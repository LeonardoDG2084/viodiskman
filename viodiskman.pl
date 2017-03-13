#!/usr/bin/perl

use strict;
#use warnings;
use Getopt::Long;
use Term::ANSIColor qw(:constants);



require POSIX;

# Variaveis Globais 

my $PASSWORD; 								# Senha utilizada para logar no VIO.
my $LOGIN;									# Login utilizado para logar no VIO.
my $HELP;									# Exibe a ajuda do script.
my $VIO;									# IP do VIO.
my $BACKUP;									# Opção de backup Gera um arquivo no formado CSV com as infomacoes do LSMAP + PCMPATH
my $MKVDEV;									# Opção de alocação dos discos nos vhosts conforme entrada gerada pela opção BACKUP.
my $RMVDEV;									# Opção de remoção de todos os hdisk de um determinado vhost;
my @PCMPATH;								# Armazena a lista de discos alocados atraves do comando pcmpath (SDDMPIO).
my @PCMPATH_OUT;							# Array multidimencional que armazena os dados do hdisk, serial da LUN e Serial Stg.
my @LSMAP_OUT;								# Array multidimencional que armazena os dados do vhost, hdisk e VTD.
my @VIO_VADAPTER;							# Armazena a lista de Vhosts presentes no vio.
my $HDISK;									# Contem a informação do hdisk[0-9].
my $VTD;									# Contem o nome do VTD.
my $SERIAL;									# Contem o Serial+ID da LUN do Stg.
my $STG_ID;									# Contem o Serial do Stg.
my $DSK_ID;									# Contem o ID da LUN.
my $VADAPTER;								# Contem o Vadapter (vhost).
my $FILE_IN;								# Arquivo de Input dos dados gerada pela saida do script com a opção -b
my $VHOST;									# Contem o nome do vadapter a ser selecionado
my $CLI;									# Sigla de 3 Letras com o nome do cliente
my $BUILD;								# 
my $ALOCATE;
my %CLIENTID;
my $SIZE;
my $SSHPASS;
my $REMOVE;

# Opçoes do Script

my $OPC = GetOptions(	'login|l:s' 	=>  \$LOGIN,
		 				'password|p:s' 	=>  \$PASSWORD,
		 				'ip|i:s'	 	=>  \$VIO,
						'dump|d'	 	=>  \$BACKUP, 
						'build|b' 		=>  \$BUILD,
						'file|f:s'		=>  \$FILE_IN,
						'vhost|v:s'		=>  \$VHOST,
						'remove|r'		=>  \$REMOVE,
						'alocate|a'		=>  \$ALOCATE,
						'customer|c:s'	=>  \$CLI,
		 				'help|h'		=>  \$HELP);

# Variaveis de Data

my $DATE = strftime('-%d-%b-%Y-%H-%M',localtime);
use POSIX qw/strftime/;

# Variaveis de Arquivo

my $FILE_OUT = "$DATE.csv";		# Formato do arquivo gerado pela opção Backup]

# Variaveis de Contagem

my $j = 0;
my $i = 0;

# Parametrização dos Storages, inserir o CODIGO do DS

my %STG = (
	"7566331" => 'DS801',
	"7542371" => 'DS802',
	"75HR261" => 'DS803',
	"82LW931" => 'DS804',
	"82LW901" => 'DS805',
	"75BBHM1" => 'DS806',
	"7573631" => 'DS807',
	"82PP251" => 'GPA02',
	"82PT241" => 'GPA01',
	"82ND381" => 'GPA04',
	"82MZ231" => 'GPA08',
	"99999999" => 'XIV01',
	"99999999" => 'XIV02',
	"99999999" => 'XIV03',
	"99999999" => 'XIV04',
	"600507680C80800BE0" => 'SVC04',
	"600507680C808004B0" => 'SVC05',
	"600507680180863410" => 'SVC03',
	"6005076801A102E920" => 'SVC02',
	"60050768018382F9C8" => 'SVC01',
	"82WD441" => 'ADP01',
	"6005076802810DABD0" => 'MV702',
	"6005076802810E1BE8" => 'MV701',
);

# Parametrização de Clientes, para o uso com o parametro -d (DUMP)

my %COSTUMER = (
   "vhost0" => '',
   "vhost1" => '',
   "vhost2" => '',
   "vhost3" => '',
   "vhost4" => '',
   "vhost5" => '',
   "vhost6" => '',
   "vhost7" => '',
   "vhost8" => '',
   "vhost9" => '',
   "vhost10" => '',
   "vhost11" => '',
   "vhost12" => '',
   "vhost13" => '',
   "vhost14" => '',
   "vhost15" => '',
   "vhost16" => '',
   "vhost17" => '',
   "vhost18" => '',
   "vhost19" => '',
   "vhost20" => '',
   "vhost21" => '',
   "vhost22" => '',
   "vhost23" => '',
   "vhost24" => '',
);   

sub usage
{
	local $Term::ANSIColor::AUTORESET = 1;
	print "
	Este programa tem como objetivo facilitar as operações comuns executadas nos VIOs que virtualizam disco.
	Todo resultado gerado por esse script é mostrado na tela ou em um arquivo de saida, NÃO é executado no VIO.\n\n"; 
	
    print BOLD "\t-l | --login\t";      
    print "- Login: Usuario utilizado para conexão com o VIO.\n";
	
    print BOLD "\t-h | --help\t";
    print "- Help: Exibe a tela de uso do script.\n";
    
	print BOLD"\t-p | --password\t";
    print "- Password: Senha de conexão ssh com o VIO.\n";
    
    print BOLD "\t-i | --ip\t";
    print "- VIO: IP de conexão do VIO.\n";
    
    print BOLD "\t-f | --file\t";
    print "- File: Este parametro somente é utilizado em conjunto com as opções -k, este é o arquivo de
					  entrada utilizado para alocação de discos.\n";

    print BOLD "\t-v | --vhost\t";
    print "- Virtual Host: Este parametro só pode ser utilizado em conjunto com as opções -b e -m, sendo 
    				          opcional com a opção -b onde pode ser definido um vhost para backup. Em conjunto com a
    				          opção -m obrigatorio a opção -a define o vhost de origem onde os discos serão alocados.\n";
    				          
    print BOLD "\t-c | --customer\t";
    print "- Customer: Este parametro só pode ser utilizado em conjunto com a opção -m, serve para
    				          designar qual cliente pertence a LUN. Utilizando 3 caracteres.\n";
    
   #############
   ## ALOCATE ## - OK
   ############# 				          
   
   print BOLD "\t-a | --alocate \t";
   print "- Alocate: Este parametro permite alocar os discos utilizando como entrada um arquivo TXT com
    				          a relação do Serial do Storage mais ID de LUN, conforme padrão descrito abaixo, o serial do 
    				          storage deve estar presente na variavel %STG para que o script possa gerar o LABEL de acordo.

    				    Exemplo do arquivo TXT:

					  \n";
   print BOLD "\t\t\t\t\t 7566331DE28\n";
   print BOLD "\t\t\t\t\t 7566331DE29\n";
   print BOLD "\t\t\t\t\t 7566331DE2A\n";
   print BOLD "\t\t\t\t\t 7566331DE2B\n";
   print BOLD "\t\t\t\t\t 7566331DE2C\n";
   print BOLD "\t\t\t\t\t .....\n";
   print BOLD "\t\t\t\t\t 7566331DE30\n";
   print BOLD "\t\t\t\t\t 7566331DE31\n\n"; 
   print "\t\t\t\t\t Sintaxe:\n\n";				
   print BOLD "\t\t\t\t\t viodiskman.pl -l usuario -p senha -v 127.0.0.1 -f luns.txt -v vhost4 -c RIG -a\n";
    
   ##########
   ## DUMP ## - OK
   ##########
    
    print BOLD "\t-d | --dump\t";
	print "- Dump: Esta opção só pode ser utilizada em conjunto com as opções (-l -p -v),
					  a opção -d permite obter as informações de alocações de discos (lsmap -all) 
					  bem como as informações do software de multipathing. As informações são organizadas
					  em um arquivo no formado CSV, para uso posterior do script utilizando outras opções
					  ou para efeito de relatorio da situação atual do VIO. A opção -b pode ser utilizada 
					  em conjunto com a opção -a definindo um vhost para backup, fazendo assim apenas uma
					  lista de um determinado vhost e todos os seus discos alocados.
					 
					  Sintaxe:
					  \n";
   print BOLD "\t\t\t\t\t  viodiskman.pl -l usuario -p senha -d [-v vhostXX] (Para executar o dump de um determnado vhost)\n";
   print "\t\t\t\t\t  ou\n";					  
   print BOLD "\t\t\t\t\t  viodiskman.pl -l usuario -p senha -d\n";	
   print "\n";				   
   
   ############
   ## REMOVE ## - OK
   ############
   
   print BOLD "\t-r | --remove\t";				  
   print "- Remove: Esta opção só pode ser utilizada em conjunto com as opções (-l -i -f),
					  a opção tem a função de remover todos os discos de uma lista.
					  
					  Sintaxe:
					  \n";
   print BOLD "\t\t\t\t\t  viodiskman.pl -l usuario -p senha -i IP -f arquiv_disco.txt -r\n\n";   					  
   print "\t\t\t\t\t  Saida:\n";
   print BOLD "					  
					  rmvdev -vtd IRM_DS803_0000 ; rmvdev -vdev hdisk34
					  rmvdev -vtd IRM_DS803_0001 ; rmvdev -vdev hdisk35
					  rmvdev -vtd IRM_DS803_0002 ; rmvdev -vdev hdisk36
					  rmvdev -vtd IRM_DS803_0003 ; rmvdev -vdev hdisk37\n\n";					  
   print BOLD "\t-b | --build\t"; 
   
   ###########
   ## BUILD ## - OK
   ###########
                        
   print "- Build: Esta opção permite gerar os comandos de alocação de discos em um ou mais vhost, a partir de 
   					  um arquivo gerado preveamente pela opção (-d).
   					  Pode-se usar esta opção com dois parametros opcionais (-c e -v), estas duas flags irão 
   					  alocar os discos contidos no arquivo em um determinado vhost (mesmo que o arquivo 
   					  contenha varios) e com um padrão de nome para o VTD coforme o exemplo abaixo:\n";
   print "\t\t\t\t\t  Sintaxe:\n\n";				  
   print BOLD "\t\t\t\t\t  viodiskman.pl -l usuario -p senha -i 129.39.186.123 -f Dump-12-Mar-2012-17-35.csv -a vhost4 -c SHR\n\n";
   print "\t\t\t\t\t  Saida:\n\n";
   print BOLD "\t\t\t\t\t  sudo /usr/ios/cli/ioscli mkvdev -vdev hdisk1 -vadapter vhost4 -dev SHR_DS804_1234\n";
   print BOLD "\t\t\t\t\t  sudo /usr/ios/cli/ioscli mkvdev -vdev hdisk2 -vadapter vhost4 -dev SHR_DS804_1235\n";
   print BOLD "\t\t\t\t\t  sudo /usr/ios/cli/ioscli mkvdev -vdev hdisk3 -vadapter vhost4 -dev SHR_DS804_1236\n\n";
   
   print "			  Sem a utilização das flags (-c e -v) o comando irá gerar uma lista de alocações com base nas 
   					  informações presentes no arquivo (-f) utilizando o mesmo vhost e VTD apenas mudando o hdisk 
   					  caso o mesmo tenha sido alterado após o comando cfgmgr ou cfgdev\n";
   print "\t\t\t\t\t  Sintaxe:\n\n";
   print BOLD "\t\t\t\t\t  viodiskman.pl -l usuario -p senha -i 129.39.186.123 -f Dump-12-Mar-2012-17-35.csv \n\n";
   print "\t\t\t\t\t  vhost4;hdisk69;8E02_BRHOPDB;;14;7566331;8E02;DS801\n";
   print "\t\t\t\t\t  vhost4;hdisk89;8E04_BRHOPDB;;14;7566331;8F04;DS801\n";
   print "\t\t\t\t\t  vhost4;hdisk70;8F00_BRHOPDB;;14;7566331;8F00;DS801\n\n";
   print "\t\t\t\t\t  Saida:\n\n";
   print BOLD "\t\t\t\t\t  sudo /usr/ios/cli/ioscli mkvdev -vdev hdisk70 -vadapter vhost4 -dev 8E02_BRHOPDB\n";
   print BOLD "\t\t\t\t\t  sudo /usr/ios/cli/ioscli mkvdev -vdev hdisk90 -vadapter vhost4 -dev 8E04_BRHOPDB\n";
   print BOLD "\t\t\t\t\t  sudo /usr/ios/cli/ioscli mkvdev -vdev hdisk71 -vadapter vhost4 -dev 8F00_BRHOPDB\n\n";
   
   					  
   					  
   					  
   					  
   					   
       					
   print "Changelog:	Versão: 1.1 - 08/07/2012 - Removida a dependencia do pacote sshpass, agora so será necessario o 
          sshpass em caso de nao haver chave ssh\n";
   print "		Versão: 1.0 - 26/04/2012 - Lançamento uhuu!!!\n";				      				   					  					  			      				   					  					  
};

###########################################################
# Função:
#
# Obtem a data do sistema para uso no nome do arquivo 
# de saida.
#
# Versão: 1.0
# Data: 21/03/2012
############################################################ 

sub date {

    my $TIME;
    my $TIME_STAMP;

    $TIME = localtime;
    $TIME_STAMP = sprintf("%02d/%02d/%04d"
                          , $TIME->mday
                          , $TIME->mon+1
                          , $TIME->year+1900);
    return $TIME_STAMP;
};

###########################################################
# Função:
#
# Esta função é utilizada para obter os dados do driver SSDPCM.
# Ele obtem as informações, a partir do comando "pcmpath query device"
#
# Dados de Saida:
# 
# @PCMPATH_OUT[0][0] - hdisk[0-9]*
# @PCMPATH_OUT[0][1] - Serial do Stg
# @PCMPATH_OUT[0][2] - [0-9]{4} - ID da LUN
# @PCMPATH_OUT[0][3] - Label do STG com base no conteudo do Hash %STG
#
# Versão: 1.0
# Data: 21/03/2012
############################################################ 
	
sub pcmpath 
{	
	my $i = 0;
	# Obtem as informaçóes de discos alocados atraves do comando pcmpath dos dispositivos DS8000
	print "[INFO] Conectando no Servidor...\n";
	@PCMPATH = `$SSHPASS ssh -l $LOGIN $VIO 'sudo pcmpath query device -d 2107| egrep "DEV|SERIAL"' 2> /dev/null`;
	print "[INFO] Coletando informações do pcmpath. Device 2107\n";
	
	for my $LINE (@PCMPATH)
	{
		if ($LINE =~ /DEV/)
		{
			$LINE =~ /(hdisk[0-9]*)/; 			# Identifica a linha cuja informação contem o hdisk.
			$HDISK = $1;
		}
		elsif ($LINE =~ /SERIAL/)				# Identifica a linha cuja informação contem o serial do Stg.
		{
			$SERIAL = substr ($LINE, 8);		
			chomp ($SERIAL);
			$STG_ID = substr ($SERIAL, 0, 7);	# Identifica o serial do Stg.
			$DSK_ID = substr ($SERIAL, -4);		# Identifica o serial da LUN.
			
			# Armazena no array multi-dimensional as informaçoes: 
			# na seguinte sequencia: 
			# hdisk - Serial do Stg - ID da LUN - Label do Stg.
			
			$PCMPATH_OUT[$i++] = [$HDISK, $STG_ID, $DSK_ID, $STG{$STG_ID}];
		};
	};
	$SIZE = @PCMPATH_OUT;
	print "[INFO] Foram encontrados: $SIZE discos.\n";
	undef @PCMPATH;
	
    # Obtem as informaçóes de discos alocados atraves do comando pcmpath dos dispositivos SVC
	@PCMPATH = `$SSHPASS ssh -l $LOGIN $VIO 'sudo pcmpath query device -d 2145 | egrep "DEV|SERIAL"' 2> /dev/null`;
	$SIZE = @PCMPATH;
	print "[INFO] Coletando informações do pcmpath. Device 2145\n";
	print "[INFO] Foram encontrados: $SIZE discos.\n";
	for my $LINE (@PCMPATH)
	{
		if ($LINE =~ /DEV/)
		{
			$LINE =~ /(hdisk[0-9]*)/; 			# Identifica a linha cuja informação contem o hdisk.
			$HDISK = $1;
		}
		elsif ($LINE =~ /SERIAL/)				# Identifica a linha cuja informação contem o serial do Stg.
		{
			$SERIAL = substr ($LINE, 8);		
			chomp ($SERIAL);
			$STG_ID = substr ($SERIAL, 0, 18);	# Identifica o serial do Stg.
			$DSK_ID = substr ($SERIAL, -4);		# Identifica o serial da LUN.
			
			# Armazena no array multi-dimensional as informaçoes: 
			# na seguinte sequencia: 
			# hdisk - Serial do Stg - ID da LUN - Label do Stg.
			
			$PCMPATH_OUT[$i++] = [$HDISK, $STG_ID, $DSK_ID, $STG{$STG_ID}];
		};
	};
	undef @PCMPATH;
};	
		
###########################################################
# Função:
#
# Está função irá obter as configurações de todos ou 
# apenas um vhost (parametrizavel atraves da flag -v) do VIO
# casando com as informações obtidas pela função pcmpath
# gerando um arquivo do tipo csv que pode ser usado por 
# outras funções do script, ou backup do VIO.
#
# Dados de Saida:
#
# $LSMAP_OUT[0][0] = vhost[0-9]*
# $LSMAP_OUT[0][1] = hdisk[0-9]*
# $LSMAP_OUT[0][2] = Label do Discos (VTD)
# $LSMAP_OUT[0][3] = Label do Cliente de 3 Digitos parametrizado pelo hash %COSTUMER
# $LSMAP_OUT[0][4] = LPAR ID do servidor para conferencia com a LPAR
# $LSMAP_OUT[0][5] = Serial do STG
# $LSMAP_OUT[0][6] = ID da Lun
# $LSMAP_OUT[0][7] = Label do STG com base no conteudo do Hash %STG
# 
# Versão: 1.0
# Data: 21/03/2012
############################################################ 

sub viodump
{	
	# Executa a função pcmpath para coletar as informações atuais do 
	# VIO que esta conectando e obter informações dos discos
	#  
	pcmpath;
	undef $i;
	
	# Obtem a saida do lsmap -all, guardando apenas os vhost configurados.
	print "[INFO] Coletando informações dos Vadapters presentes no VIO\n";
	if (! defined $VHOST)
	{
		@VIO_VADAPTER = `$SSHPASS ssh -T -l $LOGIN $VIO 'sudo /usr/ios/cli/ioscli lsmap -all -field svsa clientid -fmt :' 2> /dev/null`;
	}
	else
	{
		@VIO_VADAPTER = "$VHOST";
	};
	chomp @VIO_VADAPTER;
	for my $LINE (@VIO_VADAPTER)
	{
		 my ($SVSA,$LPARID) = split ( ":" , $LINE );
		 $CLIENTID{$SVSA} = hex($LPARID);
	};
	
	# Obtem a lista de discos alocados para cada vhost
	print "[INFO] Coletando o relacionamento de Hdisk por Vadapters\n";
	for (keys %CLIENTID)
	{
		$VADAPTER = "$_";
		my @VIO_VTD = `$SSHPASS ssh -T -l $LOGIN $VIO 'sudo /usr/ios/cli/ioscli lsmap -vadapter $VADAPTER -field backing vtd' 2> /dev/null`;
		
		for my $LINE (@VIO_VTD)
		{
			if ($LINE =~ /Backing/)
			{
				$LINE =~ m/(hdisk[0-9]*)/;			# Identifica a linha que contem a informação do hdisk.
				$HDISK = $1;
			}
			elsif($LINE =~ /VTD/)
			{
				$LINE =~ /(^VTD.*)/;				# Identifica a linha que contem a informação do VTD.
				$VTD = substr $1, 4;
				$VTD =~ s/\s+//;					# Remove os espacos vazios a esquerda.
				
				# Array multi-dimensional que contem a 
				# informação do Vadapter (vhost) - Hdisk - Nome do VTD
				$LSMAP_OUT[$i++] = [$VADAPTER, $HDISK, $VTD, $COSTUMER{$VADAPTER}, $CLIENTID{$VADAPTER}];
				
			};
		};
	};
	$SIZE = @LSMAP_OUT;
	
	# Nesse loop a informação do hdisk presente nos 2 Arrays (LSMAP_OUT e PCMPATH_OUT) são 
	# correlacionadas, adicionando a informação presente no array PCMPATH_OUT no array LSMAP_OUT
	
	for ($i = 0 ; $i < @LSMAP_OUT ; $i++)
	{
		for ($j = 0 ; $j < @PCMPATH_OUT ; $j++)
		{
			if ("$LSMAP_OUT[$i][1]" eq "$PCMPATH_OUT[$j][0]")
			{
				$LSMAP_OUT[$i][5] = $PCMPATH_OUT[$j][1];
				$LSMAP_OUT[$i][6] = $PCMPATH_OUT[$j][2];
				$LSMAP_OUT[$i][7] = $PCMPATH_OUT[$j][3];
				$j = "0";
				last;
							
			};
		};
	};
	
	undef $i;
	
	print "[INFO] Gerando DUMP do Servidor!\n";
        print "=======================================================\n\n";
	open FILE_OUT, "> Dump-$VIO$FILE_OUT";
		for ( $i = 0; $i < @LSMAP_OUT ; $i++)
		{
			print FILE_OUT "$LSMAP_OUT[$i][0];$LSMAP_OUT[$i][1];$LSMAP_OUT[$i][2];$LSMAP_OUT[$i][3];$LSMAP_OUT[$i][4];$LSMAP_OUT[$i][5];$LSMAP_OUT[$i][6];$LSMAP_OUT[$i][7]\n";
			
		};
	close FILE_OUT;
	print "[INFO] Concluido!\n";
	print "[INFO] Arquivo gerado: Dump-$VIO$FILE_OUT \n";
};

###########################################################
# Função:
# 
# Esta função irá criar os comandos de mkvdev do VIO com 
# base em um arquivo gerado pela função -d (backup), 
# principal objetivo seria voltar as configurações originais
# do VIO
# 
# Versão: 1.0
# Data: 21/03/2012
############################################################

sub remove
{
	# Executa a função pcmpath para coletar as informações atuais do 
	# VIO que esta conectando e obter informações dos discos
	#  
	pcmpath;
	undef $i;
	# Obtem a saida do lsmap -all, guardando apenas os vhost configurados.
	print "[INFO] Coletando informações dos vadapters presentes no VIO\n";
	@VIO_VADAPTER = `$SSHPASS ssh -T -l $LOGIN $VIO 'sudo su - root -c /usr/ios/cli/ioscli lsmap -all -field svsa clientid -fmt :' 2> /dev/null`;
	chomp @VIO_VADAPTER;
	for my $LINE (@VIO_VADAPTER)
	{
		 my ($SVSA,$LPARID) = split ( ":" , $LINE );
		 $CLIENTID{$SVSA} = hex($LPARID);
	};
	# Obtem a lista de discos alocados para cada vhost
	print "[INFO] Coletando o relacionamento de Hdisk por Vadapters\n";
	for (keys %CLIENTID)
	{
		$VADAPTER = "$_";
		my @VIO_VTD = `$SSHPASS ssh -T -l $LOGIN $VIO 'sudo su - root -c /usr/ios/cli/ioscli lsmap -vadapter $VADAPTER -field backing vtd' 2> /dev/null`;
		
		for my $LINE (@VIO_VTD)
		{
			if ($LINE =~ /Backing/)
			{
				$LINE =~ m/(hdisk[0-9]*)/;			# Identifica a linha que contem a informação do hdisk.
				$HDISK = $1;
			}
			elsif($LINE =~ /VTD/)
			{
				$LINE =~ /(^VTD.*)/;				# Identifica a linha que contem a informação do VTD.
				$VTD = substr $1, 4;
				$VTD =~ s/\s+//;					# Remove os espacos vazios a esquerda.
				
				# Array multi-dimensional que contem a 
				# informação do Vadapter (vhost) - Hdisk - Nome do VTD
				$LSMAP_OUT[$i++] = [$VADAPTER, $HDISK, $VTD, $COSTUMER{$VADAPTER}, $CLIENTID{$VADAPTER}];
				
			};
		};
	};
	$SIZE = @LSMAP_OUT;
	# Nesse loop a informação do hdisk presente nos 2 Arrays (LSMAP_OUT e PCMPATH_OUT) são 
	# correlacionadas, adicionando a informação presente no array PCMPATH_OUT no array LSMAP_OUT
	
	for ($i = 0 ; $i < @LSMAP_OUT ; $i++)
	{
		for ($j = 0 ; $j < @PCMPATH_OUT ; $j++)
		{
			if ("$LSMAP_OUT[$i][1]" eq "$PCMPATH_OUT[$j][0]")
			{
				$LSMAP_OUT[$i][5] = $PCMPATH_OUT[$j][1];
				$LSMAP_OUT[$i][6] = $PCMPATH_OUT[$j][2];
				$LSMAP_OUT[$i][7] = $PCMPATH_OUT[$j][3];
				$j = "0";
				last;			
			};
		};
	};
	undef $i;
	print "[INFO] Gerando DUMP do Servidor!\n";
        print "=======================================================\n\n";
		my @DUMP;
		open FILE_IN, "$FILE_IN" or die "[ERRO] Impossivel abrir arquivo";
		while (<FILE_IN>)
		{
			chomp;
			if (length($_) == 11) 				# Para Luns de DS8K
			{
				$DUMP[$i][0] = substr ($_, 0, 7);
				$DUMP[$i][1] = substr ($_, 7, 9);
			}
			else 								# Para Luns de SVC
			{
				$DUMP[$i][0] = substr ($_, 0, 18);
				$DUMP[$i][1] = substr ($_, -4);
			};
			$i++;
		};
		print "$DUMP[$i][0]$DUMP[$i][1]\n";
		for ($i = 0 ; $i < @DUMP ; $i++)
		{
			for ($j = 0 ; $j < @PCMPATH_OUT ; $j++)
			{
				if ("$DUMP[$i][0]$DUMP[$i][1]" eq "$LSMAP_OUT[$j][5]$LSMAP_OUT[$j][6]")
				{			
					print "/usr/ios/cli/ioscli rmvdev -vtd $LSMAP_OUT[$j][2] ; rmdev -dl $LSMAP_OUT[$j][1]\n";
					$j = "0";
					last;			
				};
			};
		};
};

###########################################################
# Função:
#
# Esta função irá gerar os comandos de alocação do 
# VIO com base em um arquivo preveamente gerado pela 
# função "backup" a partir de outro VIO ou o mesmo caso o 
# a identificação dos hdisk seja difernte do gerado pela 
# função -b, é importante gerar o arquivo arquivo de imput 
# com o parametro (-b), especificando apenas um vadapter/vhost (-v).
# O comando irá gerar um arquivo com os comandos de alocação
# (mkvdev) já com o padrão de nome utilizado pelo VI. 
# Por isso é importante inserir a sigla do Cliente. 
#
# Versão: 1.0
# Data: 21/03/2012
############################################################  

sub rebuild
{
	# Obtem as informações atuais do MPIO do VIO. 
	pcmpath;
	my @DUMP;
	# Carrega o arquivo gerado pela opção (-d) "Backup"
	
	open FILE_IN, "$FILE_IN" or die "Impossivel abrir arquivo";
		while (<FILE_IN>)
		{
			chomp;
			($DUMP[$i][0] , $DUMP[$i][1] , $DUMP[$i][2] , $DUMP[$i][3] , $DUMP[$i][4] , $DUMP[$i][5] , $DUMP[$i][6], $DUMP[$i][7]) = split (/;/, $_);
			$i++;
		};
		print "[INFO] Gerando conjunto de comandos\n";  
                print "=======================================================\n\n";
		for ($i = 0 ; $i < @DUMP ; $i++)
		{
			for ($j = 0 ; $j < @PCMPATH_OUT ; $j++)
			{
				if ("$DUMP[$i][5]$DUMP[$i][6]" eq "$PCMPATH_OUT[$j][1]$PCMPATH_OUT[$j][2]")
				{
					$DUMP[$i][8] = $PCMPATH_OUT[$j][0];
					if ( defined $CLI && defined $VHOST )
					{
						print "sudo /usr/ios/cli/ioscli mkvdev -vdev $DUMP[$i][8] -vadapter $VHOST -dev ".$CLI."_$DUMP[$i][7]_$DUMP[$i][6]\n";
					}
					else
					{
						print "sudo /usr/ios/cli/ioscli mkvdev -vdev $DUMP[$i][8] -vadapter $DUMP[$i][0] -dev $DUMP[$i][2]\n";
					}
					$j = "0";
					last;			
				};
			};
	};
};

###########################################################
# Função:
#
# Esta função irá gerar os comandos de alocação do 
# VIO com base em um arquivo criado contendo o Serial do Storage 
# seguido do id de lun conforme exemplo abaixo. O script irá  
# pesquisar o hdisk equivalente e consequentemente criar os 
# comandos de alocação conforme as luns presentes no arquivo.
#
# Versão: 1.0
# Data: 21/03/2012
############################################################  

sub alocate
{
	# Obtem as informações atuais do MPIO do VIO. 
	pcmpath;
	my @DUMP;
	open FILE_IN, "$FILE_IN" or die "[ERRO] Impossivel abrir arquivo";
		while (<FILE_IN>)
		{
			chomp;
			if (length($_) == 11) 				# Para Luns de DS8K
			{
				$DUMP[$i][0] = substr ($_, 0, 7);
				$DUMP[$i][1] = substr ($_, 7, 9);
			}
			else 						# Para Luns de SVC
			{
				$DUMP[$i][0] = substr ($_, 0, 18);
				$DUMP[$i][1] = substr ($_, -4);
			};
			$i++;
		};
	        print "[INFO] Gerando conjunto de comandos\n";	
		print "=======================================================\n\n";	
		for ($i = 0 ; $i < @DUMP ; $i++)
		{
			for ($j = 0 ; $j < @PCMPATH_OUT ; $j++)
			{
				#print "$DUMP[$i][0]$DUMP[$i][1]\n";
				#print "$PCMPATH_OUT[$j][1]$PCMPATH_OUT[$j][2]\n";
				if ("$DUMP[$i][0]$DUMP[$i][1]" eq "$PCMPATH_OUT[$j][1]$PCMPATH_OUT[$j][2]")
				{
					$DUMP[$i][2] = $PCMPATH_OUT[$j][0];
					print "sudo /usr/ios/cli/ioscli mkvdev -vdev $DUMP[$i][2] -vadapter $VHOST -dev ".$CLI."_$STG{$DUMP[$i][0]}_$DUMP[$i][1]\n";
					$j = "0";
					last;			
				};
			};
		};
};


sub sshpass_bin
{
	if (defined $PASSWORD)
	{	
		system ("which sshpass 1 > /dev/null ") or die "[ERRO] SSHPASS não instalado!!\n";
		$SSHPASS = "sshpass -p $PASSWORD";
	}
	else
	{
		$SSHPASS = " ";
	};

};

sub sshtest
{
	print "[INFO] Testando conexao ssh...\n";
	sshpass_bin;
	if (defined $PASSWORD)
	{
		system("$SSHPASS ssh -T -l $LOGIN $VIO 'exit' 2> /dev/null ");
		if ($? != 0 )
		{
			print "[ERRO] Nao foi possivel acesso via ssh, verifique sua senha ou conexoes de rede.\n";
			exit 1;
		};	 	
	}
	else
	{
		system("ssh -T -l $LOGIN $VIO 'exit' 2> /dev/null ");
	        if ($? != 0 ) 
                { 
                        print "[ERRO] Nao foi possivel acesso via ssh, verifique sua senha ou conexoes de rede.\n";
			exit 1;
                };
	};

};

# Validação dos Binarios e conexão ssh 

# Verifica os parametros parametros inseridos
	if ( defined $BACKUP && defined $LOGIN && defined $VIO )
	{	
		sshtest;
		sshpass_bin;
		viodump;	
		exit 0;
	}
	elsif ( defined $REMOVE && defined $FILE_IN && defined $LOGIN && defined $VIO )
	{
		sshtest;
		sshpass_bin;
		remove;
		exit 0;
	}
	elsif ( defined $BUILD && defined $LOGIN && defined $VIO && defined $FILE_IN )
	{
		sshtest;
		sshpass_bin;
		rebuild;
		exit 0;
	}
	elsif ( defined $FILE_IN && defined $ALOCATE && defined $LOGIN && defined $VIO && defined $VHOST && defined $CLI )
	{
		sshtest;
		sshpass_bin;
		alocate;
		exit 0;
	}
	else
	{
		usage;
		exit 1;
	};
