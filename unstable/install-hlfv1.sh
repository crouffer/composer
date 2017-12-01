ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.17.0
docker tag hyperledger/composer-playground:0.17.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �� Z �=�r��r�Mr�A��)U*�}��V�Z$ Ey�,x�h��DR�%��;�$D�qE):�O8U���F�!���@^�3 ��Dٔh�]%�����tO�LP��&�C��j[	�ܭۖgV�ݖ��~@ ��d��K��'��(?��(�ј"(�1&��GH���o�q���#��g�s3޴�_)���-s�H+��L׈��qs�^�����b�$�{��z?�e�-\��F�Ml�T�Ď��Cm[���$
��5aMX��V8���n��*�a�p}Dr���F��(�\�s��j�b�Z�J�Bt�a6D�*��r����?��_��#��;'�+��	��lW���eYa�1kl����_�$Q�*RT�b0�q9���s�'�Tt3R�N�s,��◟"��>��Mu-|�L�����݃b*�Fxwţg<����T�[�a�*�a�,��
&�?�}:��U�Ee!����0A�5�`��b�Ֆn���M	�M�%!������b��,���	���Z���c��R���o��E�#��b��\r�T��u�_��*�6�(�¢�'W���z�����&6*�4��]뢭���mJt&�T�lU�j����鸨��tS'��m�g�u��K�	��ew!��m�.�@9��.+I�mД�붝�Hr^%�Y���M*ײ'L�C�+V�܆e��5 ���3t���[�i��:�I�ˮ:���gi����ҚZ�f/ű�v�Cy�(����[�t�¶��ψ��m
я�n�gk�&���&mbV���d�&Ť��'�b���_�~������`|���XN���Z?w�X�<�e�G5�4;���b�I�K�?I�%���'��B����?�	�V�y�Fur�EM�06��&-�@"A�g��Y
8\���Z��ϸK��7��V�Bm�><��zC��=,�?l �G�^P�&��5,�oC}�6�j���#��E`�FL�0�Q�_�Q�j:T.�V��k�n��H٫�.��-��P��{E{1��@k���)����:H�{�Ga}�7`:��q�ߦ3�a�r<İO �1m�/�CmGV�����S�I�:�#���PQm�� �4��C��7@�&��b�PvinoǊT{��E�ܾ����j�׮ۀ��q��Rt��3vr�A4u��@3l�K�s�Wg�)����:��A�������ϸ�P�D�I�- ��gp�^ ���r���Z�W�����*��7_� ���G������5�#��k\�2�be�Za��O'ҽ��R���ߘ�.��y�b���	�?�{�c���2�<�,.��JT�E1���y�o'��0�u��9�-�	���l��9j�nڸ��h�mS�4����.��7>A�p�\�})U��7~�D�b�K`��`e�r�j���l���Y5Y̥�f���n�����jl��;�3⮂��x-ZAè��<����%4Z`���ᐛiE�	�,�f��Q��o����˹|f��|3�#h�x��!0XU�ٵ&�����,������Ļ��+4�z�-O�x�Oh�&��;��H�my#�� �8F�ת�G/�^0���,�)����[a�����#��v�"��� ~t�_�v��_ϓ۳-��8�j0���b��?QX������c^5���n9��&N'*�U҆��f[-t&�E%, x��M>�F_��>0L����ާ8M���0�������\���{�f���B�	b(�P��Qo!�}��}�u���`�������1q�=�>��řiL�������$,�p���R���!������������f�n���ێ��m[�*jۺ���6�N��.x���՞�������o�M8������c�~�����D�O�'�����?F���%���9N�qI�#��U��l��e�?8*�݊D��X
��83wB�,R~��4K���r	��n��]C���1I�
��b0�����=�l�*���'��PE,�H���+��q�ؙ3���3�����>��L��4p�̅��[����Y.�L[���G��&����Jl�����T��Tk�Q��yA����.�,zt�Y=>��Z�����a���ob�� $���<_�����c
X6��ɑ�i�je����W���R����b��+�Q��/K������ �s���?3�hM?����͚�¡�C`�!Lύ�ht��n������H/�QoC'R��P�G���4Q(F+�@�����<���V�'�ù����ġ���C���e��Ut�߯N�-��v75C�jT!����WЀ\��'���8~$d��3t��O�7�+Xӹ>��!Uzn��gd�P���@��E���1�
7�P}�̀P��ElW��t/q|��~B��,z�"n�M��^��[%\t޻w������$�pMp�G�#�n���H�Y��q��"�芡�hh����\/#��4��&��6�����]*F�	����v6����tP��o�׶~r2uK�(��kXC��F�F��`��v.M�w�A��^����<r���]q0f�W���������5/	�n۵�sR���@��f!���.�x]Tت��L`,�$�\�@DDQƸ"�x�R��ZTX��%HM�+kZB��$**��*��,hX\��DE�c������;M.�)��µ��M:�oB
��p����@��Pf(d��r�3��h(^w��be�� �{Bi*����2B��d)D!o@�4��i���5Y��`"�4{�F)��CLͱz��
S^�8�[,aZ)P&�_<Y�� �����(�z��Aդ�s�Ǆ��|ڻ���N��y,�K�y�9�����l˖^o��zL���O����L����������>-(h�������.�	���/���f����
?f7<��D���p�jw���#��|�~���- K�%j�r�&�Km��rZ{��Pፅ(#�U����^�Pдj��@`��[����}n�k�%��c�_�?64�h��˭�|�j���ч����/��8��؟���Y�M��.8=_S|�o���4�'�q��������E��<����|�vϧ�A���J\��E��<���o��ܻ���w��������c�Ϗ?�hE�dYJ��4Q��Uj���H�j��$KqLd��19QIDe�	%�+�5E��)��|���[n���/�ߪ��Aw��Y▾���.oK��_渔e:���^k����[�`����뛥?3J�߿����~Ƕ���^����b����=4��8}d��j;K�������0�S$4�t'H���|ލ��=�>|��3�������( ,��<�ǿ��z�:���Q�K�*(��c���w.p�X|D�U�j�UH�{�m�iQ�db��5�t�?���\bB�Ao���w<�_���y�n�s��q��2�qT���]�C��@<D!���=��es)��a�o�|.��<M�T-UW;��Z�Ղ�k�w���f�z׭L����ǹm�$wq*d ��]dv����TŃL��O��3j1Y/�r�YhT6�V%���G���z��i��!���ͷ���zǒqq,��o���>�U�l&�'��u�Qy�tNJ�iEη�*�q��Th�5wZ1;[��/k��iNʗs�n9'ѴS�&��ޚG��J~����Ӈ����ΫÃ�L9G[�J������Nδ��>.g���}�����[�@�z��I��H9ů���L-�����]|���f��d3�j���N�pV)'O�'���d��f)/'�zf3�
�w2[��S�����yr_�l����Ck�,^x�o�*n,�pT,�Jn�;ͣøQ<��mu;��%]W���I��^+��9'_�+�N�Lw���>-��;yU�� n��N&���1ު��<��b>���2ꩪ�SmU5��o�S�j.ٲO�O撉��]�iv�[�-���ݵ�T6�ץW��r/�Z����T���3��~Jv��co�T���R>&��H(G�H�<yO�R2�:���T5R��K�v�j^u�V�ʴq&��'�^���0�������jᠨn�5ٔ��Ā���
G�w,������1C����c�������(2���@��@O�ۖ�ކ7-�W
���Ϫ�C�Ɏ������O����������X����IA������\>��k�z���:��P��uA�uvv�ۖI��J�1w��
%�5)lƙ�M����oJ^L�������P(��͋,Nş_ʭ�a=���cN>lt��JW�D98ܒ6�z�qdX�Wޕ��55�>�;魲@Z$�oX��c���]o����/f�����R������,����Iܬn7�����$q��Hܬ.7����� q��Gܬ�7�w���q�|#�F��+��2�?����,��y�g�����n�}��4��[��������N.5��e��L�x+��R�~��K��Zz��fp�cg��\ξʟս�#�W�6�kEs�n�$�of��O^{��b�aY�u���w���Lu�#�8z�\Hl��z9��j}cc؁��s��o>A��n҄��o��"�1������"���������,.>���/�F�a�"MsP��yQsOh��^�uh��M�?˫��^G���  �����G���u�G!�&5��YĬU�Q���\��M\�W%��UdZU����di��R��%N�< �*��gj@(m��n����Z�~�uS�|�M46�%B�5-ڋ�B��BP��aw܆�/�@�0V/#߲��x0w�"��{�YL#�d
�8y��[t��ő�;����������G�6أ��o�!&�����9�w�]��)D#��uԵ<;��/Ԟ��U�<� v�u��:�dS�O[-�>�U_}
�l�  l"l۸K+����k���Xi]Z�����۱,F5��'c���"����^<C��~��5���"�N�:��!:)�3�����]�2���B(��4��m���6��W��>�Q�eSh_�K;{��ꏎ>Jx}��n��2�k��U~�3�ꊿ�H�n�
���CߞaÃ�G�Rfh����CRn�"Թ����g�q˪��iɛ��`��ּ�ر�)�Ic�N�T��S��EɎ�'N�N�Dj�X �hi���;$f�����A,X �Xýן8���U��ni�O/�\�{�����3��	D��f.�jG�����-�#oR�%���s���Jt�A^2s��� c0�vX�#�F��u��܈�
ȳ�I�<='}us�%����/@��ܵ_�MB@�A�+A�&�^��5ts�\� ��!<>K%�e��1Լ�:��R	�xr�l�<"��X3 ��k����\��"I��
}�mϵ�W�"_�Um�؄�?����If{�+ kr������ʇ��x�+��7"�C3��J�f�`*=sf*�"�`W,g���Y��
�.��T�!l�w�/+�ƽ��PIc؃��F5�g���܋��H<��m��V���>N�	k�ܭ���~�	�*�i����G��#���b��|����{=��Ə�4�UQ�1D<tjzC-B�ݚ�K�׿��kc ���(��u\��'�db��G�L�����{� O>O��ϳ�����������?�B#�w�����g��ͧ���}J`�'�%��^|�����1�+�*���\L��ߥR�LR��L%�t*�T"I�5Id��J(���^��5:�$I��L�T��M*��w������蛧?�̧���O�l�V?���'��K`�K�~'����W׷(��߼��[�.X�������/�����>�5�Y�������c�|�Y߾9��� ������Qp^�JJu�ɴ���-j�}�rY�9`u�t0<���u�9aW�����qpt�EΎ�"��
���3c�'��w����ϰ�-�&�C�'��xR�œ�Җ^Z=L�Ģ�ȭ��w�ޑ�P��{]xw�uڋIw�]*#s 6:n�AKH����ʨ2鑕���ye8�,�oQR�6�*�֬Cf����0~Q9�4����Q��$��\f8����AiɎ��� ^��|�v\�3���S-nbڦ�0�j��n��
6X��y�8u�Z��J���@���|��`3�S/�Y̽^�L�����L���y��q9e���-��g�+f����/�u� ;�i���"��3�9�OGX�D��J���,w���`rJm_p ��zn9=�����ȼ.:�"�1�՞Qn��{����j���3='��^�N��v��4��8��'JJ�.���@�h���b��n�/8;��RӝQɝQ�O�Q	�:�r�Ȑ�W�'�*�㥄�����??��F�=Y�J��0����!�������V�e�=L��k�ʞ뉞�[`P���nB)^O�`��9�W��l�hҥYr���.QI:F�ۖZ���9�V�]$����6)��Km!E�[2�m����M	Қ��ܧ���ȟg?����rL�J�X��W櫣*i�T�*3'+��U!�&�S�\�Sf�s*[%��Ϧ4bD�:�Vm�Ź�q��g�%�tJ��樜f�Y)I�/T�T�۪N{5LM�9�?��s�y&5�/����n<���^��{;v/�
��ҽ�
o���_X ���{���᫕o{������|�)�2��2�A�{_��������/���}H�x��a�c�{�-/�^��6�b�?|�%ž�v�߾�E�b?�ƃ?���?���������Ŀ����W����Z�Nf^�l����e�O7�Rj�wF�����y�i2?Gn�}��{���]�<�\�u�fπsa�њ���XW��u�u��6>�V�����F5�(m��X���]�e]h�_ON�XgWD����r��7�i��:�Mը��@͎�Ju��Nq�%j]�`�K1�����I�u]��3���h�/�0)ZD�Ŏ$��q���H,˝�#�`:]V���;�1��>�Jd�Ÿ�C��rz�`s����2q�`Z��^�p/�v�u
8�b�u�Mk�f��p�`�R����1���vTPi��������Qhz�V�u{4l�=(!��T�I®s}">`�ڀ2���|\n'%*�D��.��`x�>��.%�T��PQ�wJqAh���\�3媭����?y��%�B ���
r~�
27����T�RG��'E������
7\VL�	^���'|9 w���;�t���7����6g���D8]B�J�Չ��F;_s�l��5�S��Y�����V)���m�ޚh�U~�Q�(kN�m��Y,�N�B�g���0ޭ0�f�Ry{���q=E����0�G,'l��
��G���z��|q1���l/���5���1�m�
�z�Pψ�& بF�g��LM+t�R�=�Z�/5���&��;�O�"_\4 ���L�X�sEC��L�7^����a)A$H)W��LiU�L:�_]J	
��Z�����>�Hdٲ:�����U��$�[`|A�����]wF,�H�`�݂	�	�փ/&2X�¤��@�`�5���Y'���An�g��f��j����)_H'|�f�m23�֛�N�=iB�&�mv*q�u�D%e�Z�᠐4W����2��J��
,�(;J�U�H��=�~:^��F4�[�K�x�N�h��M��L�Ei���%e��a	�*�ue1#h���t%��(��1�F�$�Vs�0Y��Y���$f�HqE6�p�D��s�����^;۬rf����B�4��K?�}�"z��ע�[X��ƫ�I�U�+
u�_����hC���ᝊ���*��p7W�3[ZN���W��m˴�,��ce�7h+-�f��{�O�>%�y��|{�<Gy��c/c/�k�>c_g�ơl��C�x��7�K����>�FQ��XgL��#��c>����E�Nvd�@qΦh���x�f�7��aTu�ٶf������)z��<:���RF�������"�5���=�����/z.9�K��g��PI����6������������q�w=��z�sF��!���n��Sa(��(x*> ��9<H�}�0��m|"O�� w����v]�&x�	�}���{d�c�o؄(���=8����u|��}�c��YU�6�]l���8~���	�F�Y7��=l=��Z}C��'b�w4bG�a���Cy{���)�nz&A���q\�Z�zE�!d��Q�a��}�X��ѳ�6E����
� 5@��)�]#{`*z��5́] �3���o�#>C!�����_:�q���53U|��;�|x�~u捗2s��� ���Րm�j�F,�<�x����$��}��6�0:���IC5���C��o=��XGF�sʹ&�Xύ�5���2���qhY�Ԉ��Q����k���~r�4�mE�ɋ�9����5?��V��;!0�>�~�
[���_'� ��B��>$�P�����It��nX��1��}�a�"/�|[O�N|%��kO$:f�.�+�=���CXWw�i�XSx�`�þ}�1��z`��\��D��א���e��׿��`6��?`ТӷME��pj��oѺ�����o82x#�%�А8���ͳ �G�H�1l�85ZRB��7'q��$T+�k@����]D@�Q�٧|��c[��YSls����dM5Y�����6��2�P����O���g�4Z�k�J����2l��az�1@I��!ܗx�lz��P��N�*�`��pɽ��G�yh��1���#h剘H��te�	""b(Be\�e��^�>Nڛ��F
Գ���2�-��h2
��!�@(�&x�ؐ(���Q�ّ�0F�Ѯ
 ؉6��@��H�s�>��9��Q�8πl�ղK�7VA��z�F8�\��:�!�צ�l�n��&��x���*@�~��.���Ր�/�l5o�x��Ù (|S����c�A���~�Fd�M���f{���vv= 4A���@:ُ��N�!��(F�:ʃ+���H8b�C��@����BmŚ[ΦnԵŦ	2�8���D�\s���<_5
�h���^� '��/(�Dh
�b��݆W|�a�9�5�|cSS~��qKD���9"8oGDW����V�75�Ѿ^q�ok����Ά8���K���i2���N��������? ?�0�F��Jv�\�x%
�����0sd���g�g؆�;�1�02ғ����;��8��`�o���� ;��{Q)xx��W�|�j=/���g�G&IU�'�BʲB���&�I-I�S�~���	5�'d�T���T���Ϧd��h2��a\4`P�E.�?���0[(͏������v{<�R��G/T�U{�cB��`�峁$����eEQT&�Ve� 5�����,�RTVK'2�������`$3Y�Jk���500�#ŋ���>'.�H��[ρ�6�"����c����U{�O���ػ'��A�]낝�wd��b�W#�j�� �|�o0��r�P���USf��ل��W�k���Ү���BS�b�{���/ɺ�����s.�]ЩS�5�{��,7�tx�	0L�?�h_����ȎU�;�&N\��Zܞ���f
¥�s�I�������޺qb{�}M�������vA���<�p������ ٍ�l�������=Wm��B�p\�������"#TrUn�ӣ	�g[�ͬ��1_�jU�"=����~<����sy��ƾn�؎�'*	+?y��Q4o@m�&�Z�nW����jS�U+y�p\�v�q ��=	��8ziw����6$�f��#��lpH,�I�(۔`8r��1�2M�IΚ�{A�\��+r��'�W0@=X\U��l�z��m	�(Ly��3��/��v	���M����u�D��8����
����w#�n�ߚ�k֋���f+���jm������[m�;% 3
�c����]�n�gk�!���p;���V����
�G�*:��~�����v�8`p�wy�/�LQ$�")h�A��w�n�����Fw�q��_����]��[y������י�$�����6����o�8��;q���6���Ǵ{�u�F�=�����_����w��V���'��6�������7���G��	|���S����(���������[y�<��y���@�\=�|�$�L�WB��w�����n�-�OS�2X��D&�OgT��H�J?I���g�ښ���=�⻷j�|�x�^N*"(�yO��(��Ӥ3��:�t�{:ϺJ�2�Q��k=��g~(p<F,��s*��
8��|]E��/��O��
��b�;�G��_%�F�}M�_�\��d�'�t�6��=�9�}�cx9���c�L�hp�T�����4�{v>T�l������l]*"{�����e��y7Yӹ?$r�/��p%��;]���Xw���i�'[y�k�������u:<P8���_>���gC�~��Ǩ�����OP��(�?�?��S��U�*������_���?���W�c8��
����I��߂O���������?��+����{�*Q� ��������Y��*��?���D�CU��O�Wҿ���U �ꄫ:����O	�G<�����J���}0������H�?s7��_���(�����$)��U�5�o����s�S��ϻ�|�:�-�B���,k��)}��tn�����~޾��ݻ���O�}��E�~��U�����>_�>��E�TR��*kh�޽H�Yo�h����1y�짻L'��\h��[g�([��5v� [���y��}q��C��� ��_��|Y��~d����=��q��գ#����L�Hi�di��қnW��nO��ާ|9,�kw�KS_��;��)I�e�xG��,T���;Ʋ֞�C�a���v�����i�N��������?����V4@B�A��6 ���D�P��n���C��6����U5����H���@��?A��?����?�_@@�eI��u����H���g��� �W�������@���a��>�:��\����;g�9�\����[�d������[ٯ��?��/���ƣ�!����^��w�5�i@��`��Cym�� ��Ífc�ϴx�Q]V�vB���FA�4I�B.���;cvN���!����Y�4����c���h�œ�W�wdC���/%�*�T�K{�㿵�o_����N'd�$1�x��Xr)i��.VƔ;H&%�Ͷ��q[Lľs���x��$����=a��
l��4A�x�����ƜZ��������G����Ut��������?��C����>O�_���(��l\8g�Y��Čᙀ��� �#:�.�0�X�g�����B6d(�
��;~(��������W��ge�ӗ�DJ�V�d�,��ӡλ�(4�S�Y���>�����g��D�@]G�'��{�wGB޵���V���:��t��Rr�8%�b5Q�7��(��f������5ց������?�C�����o�@���W�������������f|B������ï�G�R���6N�q��6v�sV�	����p���e��Q�_��ڣؾ:��A3�|�]agv�>U6ؼ��P����b|g�yJwd7.�B�̏�o
�����RE\��N�1���
4��5��?����{�o 
�_��U`���`���������h�:����;�G1����k��+��/f���b:oˢ7�wV5Q�ӻ��ٲ���R��������������=}�'� ��ճ� �Jհ=Z�K�R�n� �z�h��)=tu����)���\�+�0��VSһ��km����r����z�>�Y�c̮(�\�U�Y��`���2���=끾�_^�-����ʷ; ,�%�t�)V[�U|b���I_�4�x���HR�(�C7��k<oN����L��3C��7,kaH�����D+?jRƤ����4��jɚ:�q�pܵ����-C�1��)I�sE�m�����#z�-�=1���Ќ��\d���&5:�8�c��ϒI4Ǘ����s�E�A?�4�*����Ä������������a����������W�J�2��EU������������C�?��C���O��ׄJ�!���A�4�s3F����>��B��<�G��n�A�I�x!����Y?���
����/��J�+��~p\���e������h$�g�,腹�%ktj1ї�_{��]�.�]�K#�jm?�;��Q�톒��dS&}�TV3��X\t��svx��K
��Ah���8�i���[���O�����O%�x��E<��*�*��{����*���w������?�$��"������������_E����ۗ��v0"���4��&��W^���C����y�oGf�2kJ�K:�T]����ﰬe�[���o�4���~߾�����������wQ���0�ǌ��S-yث���#��%�h�ζc��މ3'�T/��U�x�t�ζ����НO}]�[��N��<��
oڜ�����h�Ҏ}�8R��6v��*�Y�gۉ�7�sK���9I��0�
}��m�(��~���-�H�.ӡ}�x?����ʚ%әn�������F4�3����������-F�I�5c-��M7f�2K[���U�0�hc����xr�i�;�Lw("=�]P�W���քj���*��n������5�Z��ApԀ��4�MA�_%��o����o����?迏��:� � ����
����P9�?}	U T�����Kq��� ��B�/��B�o�����8�*����1��Һ_'�1�x����4��J���8~��)��*P�?��c�n �����p�w]���!�f �����ă���� ��p���_;�3����J��C8Dը��4�����J ��� ������������GE@@��fH� �������� �W���Bj 
��Q��� � �� �����j�Q#��n���C��6���Q5����h���� ��� ������+�/Kb����?��C���?���� ��0�_9P��0�_`���a��_m�
H�?��#@�U��*�dyz���� ���[�����w����:���q�ql0�C��p~��<�>h��(�a������>�s���>M3�������@��)� �_�����6�:������ow��S�'*��¿�,+�q���$=M�B�
X��#�&&���קuK��r�[[���,���I�,��wU�|�k�#z#��F�=Z�k�\��:b�Q�l'��o�4=:}2"�Pl*���S:m"�X�����ݽ���pĀ��������?_C׷V�p����H�?���������j�~3>!P����W��AH̹�������;,o���Yf�}�/[���_ĝ����?'Z���^�e��7�pXh�d}T��d�c�q�kqt&�-m�t�G)8��b�;���`o(�>E�Q�S�vT���`�2&��������w��V����#<�����(���W}��/����/�����z�?�� �������������?�����R7Q�X>�[{be�/�V���V���߳��I;E�$�M��c��%�����j�͆rZ	{��;�]���fJ�'Z'��C[?�^<f�aF��p�Kv)�e.��Tf����;���}�73��ؽ��_��[��ӣ�o���ے
C�~R���������e�>鋝f"�}IJ�e~�FR��5���I����I�zv�,��j�Z�;�^P�Ņ$��$�~��~�4�6��ٛ�ǣ�h�V�.&�6��(b+��T#f�j�7f�H��3a�qO�������~�]�����0����o���4I�����p�"��[>����[��7�?AA������A�'�W����Jt�/dQ���q��q��J���8q������@5����	��*�������}��P�����LG����k��a�6�n;I��ARo��)�Wʯ��h)����!��7KӢ�\qS���W���{��.�J~�{��x)�a_k~V��_z�E�}��7���t9��.o��[j	�ml��)�TZ5�k�Ր��6Pgw���B]�52vmTl����Fj_�T9�c�?y��ŤZ6��E���MF�{�ɮ]7-�Ժ䏧���!%�b���-�T�{���ӗv���X)����EE�����v�߲:MC~�L̔�J$Y�����S��o��a�-��{jv,����s���O�*slvDER�D"���%"�����3�E�'�<O�^�LD�v#�b)q��T��)~�7AaH�9�J�S�
��8��������[�{�������oE�F�q�,A�7篇�/̩��ߦ�P��4���|r4%�}�ؐ	�(?�Cb�����������_%����
�Ŏ��A�S��a:
{y���0�|F.<)�2�/W�U+�{��M����[������;�?�A��
������P����C�aT��_�����,�J�Z��W�������󧾓%�@_L�N��<����N����h}�S��w+�a������~��w+�ao��M�}���_�~/e?�mu?�Jr�cI%��pGVf�e7�ZK�=>�3aC����N#��/�!+ʛ 
�]���-f�|\N6�n�h���V���[�{)�a�~~���D�q"��vC58.���^���E���t1��u�q�OL&�e5���Y��͈��h�ѫI�jQb�	�V�Y�E����j���,eN4�6Z��᝶��������ٻ�&G�-��_��;��'W	��q{ІT�w9� %	$$����I��&uW��+O��*�$I��s3�ޔjf'�n%n:����NH���.��A� ��ȬJ���fI"�e)*�SY��� ���I9+g	�G��`�%J�Hn!���������~�܂�D�o��W,��D�Z��˛f��
#`VS���D>h���aE�l��>.[BՂ}�lA�/������_���e2��/
$A���Y�o���_������_��c"�������Ň����%Q��'��3��� �?<7�#�����[�JZ�z�Vmu{[��6<}5m��p�y��^M�N�n���X���Ӻ��E}zJ���	�0�-dj�Ѷ>+l����n�p�tؖ���g������CW��+l�t��W+�se`�Z������y�U2�����A��u�l�6�Q����q�eYP�M����s�`W��iLh���ɰ�%5y+k��yz\���hY��
ޅ^����a���a�G���A�0�3�V ټ>Xlj������˛�nj�7�.��(�T���R��b�R;K�Ձ�[Ҕ�ɫ�:�6Ai���`��M�B�í+��Ѥ`!/ǵBy�nwy���]:[*���X6��k���B'7%��$���b�le�#�o�j$A�����F�"A�_���T ��u�$�?Z�)>D��h"h���|�'G���H�����h�'��������^��� 	���n���G���!b�G���D��g�ߠ����#�����o(����������տ�K��!�����?M �?$������(�gD���Ϧ�#�� �G�?�_����#A\���}�������y6������"~ �G�;���!�G���?������� ����(�����?�^$B��Q�G$�S��������׭������h�GDH��������,�M��� �@�P�����#���Cy!���_��K����ؐ�Gy!bB"������G��� �@�P���!������O$�S�y��������n����/�@�"A2�M��������؀�����h���E"�����������.@�|@����I��y����"B"�_e)����&���h�c'��� �j�D�d �, U�U5M��pC"Gp�`�w��zux$��3�����G���-��[�W���_*�z��	���]�:5:�.���wP(%"�þ�VKg����V��+ۮ8��b����S��������uM4j�͇��ݚ�5����z)*%,{Y/=��M�&�s�.�I�&�i�-W���(�A��>KZBile���tx=+j[�����Dީ����M���	C�?������F}��$���Ň$�?������o�w+�^$�������'�z�*���&5H�j*ȩ�u]7G�[���JuN�_�П7&�Fw�PT�n��bA��L�0H^mf���r���5��j�IE��l���2��	5/�z�V��]�-"��H��Ϡ�ߘ��W�����D��B�_����/���P��1�� #���\�e��������ƽ�k�u�-:�n�m-�7J���?��+������b^(
��(s��O;۰��m<!�B�nZA0���߮��=�����X���� 5ԂAj�y�6�v)��AIf��f���Բf�'#��U>�U7n�)TgJ^X�x������GY��<?�k�N�pxL�+腢�R��0�`$�^9|�y~��� )����'�
�<o�/�|%�@�IP�y����nW7��E���Z���%3��;��"?�ۍ0ٌ�~AĤbv�����}q-�S���t�O+�Նe��Z"�Fy#�����"	��dP������� 4�#����?7�G\����B�?�?��܅�/�����?��C6!~ �G�7�Sę�g8����� �����?���������"A���`���5�?������0����I��2zD����������(��?���(���E"�y���H��C+@�
���n���G�?Ć��?Z�1$��g��I�	���؅��}���g׍�gMa������h�Y��܍6�C��c�G��c?��
��b��؏�b���~���b�5�w��m��~O����~[��[,��+��T�i�⬅��&=XW'�Yo,I�SƂh���Teyq� �sJ��Ӽ����X�ɩ�ð_�K�~Oa�؅�_Y)����u��i���Oq�/��%/�m~T���/��;��]���!�ΛÒBv��ŢO]0����!�K�`�t�[�{��Ua�5�a:���kdz*X`J� 5^[�iV�ӪT3;iw+q����0H��C���!v��`���5���[�%����lH���^�H���B�/��G����B��P��x���Ą����"�q7ū��_��K�3���� ��p� ��H�����ǆ���|>��� �ce9����w���W�z�6��P��E����AI?uO���m������ ���]@v�-���֥�VU��լ���4�ٕʸ�4:5Iթ�L�2�1�_�Y2�UF^{Z���iJ-n�6h,Ŏ:�I�m��x |M |*��A���A�LMs�o�������X��M�\ߣRӢ�[[�5�SZ�$0^nQ/uz��H��ײԜ��i�Q@aٔ��V=P����1���뿠�_� v�w�x�-�:���׭�����B����(���s4��N�XY�sYL2�Bi���B2�FQD6R��#4�Q�± ��	˾����##	�i�O4�?|��?�ܘ���UnGc��a���u����o8n7*ڼF~.uZ�s���C*]]�)�q��ug�vW��4�Ҝ����gd��^O*�.kP�ٮ׬�ƦT�M��84��Y� o�Ĭ����/E�?��b���"Pq7�+G�?���C"�������q@����I���Ňo��9��9�ΊJ�T�˧�<�	u�S���u�5J;B`�����c;�Y��K�q�<]�]Y���:`0��v
}fHd��R���ɶn�V�[ש �QRT���v�iڞ�]��7M!��H��?���p4��Q v���h����_(�+6��/���P���A�/����A��d���	��A��t�^��NU�X릖�R�l����u6�����1 �R�}Y vZ�a@j�{+�,��R�[)���TE�zgk�dE�O�����P>�y:���Y�߲lg�v��L�����#�VUǫ(e2;N՗����|�X�a��d>(��:O�߫TF���� ��J|�W���4^ �0 H���O뽪�͖,��T�IT������,SZ�"�*��ۂkaK]����Ê��c!=��w�f�z{�8P�H_P
s�nWʠ�T��v�Ԛ���oM}��k]�$�����h�Q�sO���SvMօj��L�jy��&��&3������S;�mee���2���4$�G�O�,�!��s���W�~}4�oo�������ql�ǋ�Ж�wb����w�o�4y�p��	��v\[3L���7�q�
%x���k{�;+_0mu��ܽ_��a����t��T�,`��] ����<,T=l�o,~�-�����d~��/��ï�/���x�ϻ�3�$K�����4������_4��Ҋa�ٛb�Oxac��m��z>\�v�װ|\6���Y��Ļ�<���`���p7��������o�������K�������u,ob��h��by�����/�:������Wo�|�������_����_���w�	�K�Wz��@����W�_ka	��W����17ۅ	O�oP����'�2lB�v����	&:p�×��6����a��ʰx[;���S�q�ʲK�M�d�]s�����c��t�v�]W����?L��d�
p�Ā:��7�/��L ��;p��y��pϰ@� \��vu�?��|:WE\����w�`��O98l�4�������'#p����Vl��X�`�?���Gwq�1��.�k
�w�NSlԋRio��*�*����>�Rx�ՋfV�Zyz�G����B�'�f��s�?���?����2�hH4�/
����@vC����'�̝�'	�'P��h� �� �LW�ބ����_6�;��q���z>�� x>���BO���5��?7`��ʼ��ʀ�u��^+�{������~�j���o͂v��<���x8���.��V5d�K�����q�JÞ�c�pc!����v��G;���_/�+��|�o�� WM [��]���b�_`Ӗ'߃�I�����=�g��Q������!kF���������K��/�\J�e�y�N�;�����U��{pMސ7�]�6@��y��Eg��ZɉGwꋮi���D�xj�o"Bx1���&�D�������g�?C���-@���a(��Q�y�?R�w����`���sX��.p��'�����;w�x��BQ���&nH34|
k�g��ir���Yq����T���r0ǯ�7���a)���� �_�k�8����ip�_������I����w��,ʖe���u=�ȧ�m�����O{M�f�����ߗ����O`z��Uz^�/x��M#l�7���ׯ�5�+�P�: ��?l*���~&4a�a��8t������X7X�O�u,Hǧ\��5���0���x�Q������	���'s3�l{�/�*|E�~ǯ�s��a������,"��S��ǯV�y��cu�QO������}���a���2T�}<),������W���J����>�
�£����~�p�rI�}{��������ZX�:!suw��;�����K��|ϑ�����Z�y����+�����Î3徭�������vx<��[��>��0$I˲B ����%Ƒ$-O�������4��ڂ]�ꝙ*���G�H�~����UFh��L�i�3]���Qs@H��h-h.ho �!�\a9�X�sA8�7@!"���]U]�U3�-u��?�x������V; F��@���m�nE��!�	G%! ��(PшkQA�	4�D>2� �_�����<�Z��B�A�I�P��;���dG�r���e%Y�Ѯ���H4������RH�4�V<�6�}PE����D@i�?�A:���|0��Y�k�2��畂���Y�F�3�-����xŔ�� [��9U��8=&���|a����j�����������Z�/����lc�r�t�T.��=q�̞��΅��|���s��\�Z�7�/�
Γ�f��_(�⿘ us�s-�e��6���Ƃ�
-h�um�
gw��n��������������(,��������Z���5A8��q^�/	��L8x��w-����#�k�7�l����/m������C9�
�4�E�"%RtLh�ڴ����V,H#�LS2�c�X�:��bT+e��(��w|�6X%L������p���#��# �^A{�K�� ��p�����ě���~��Ϳ�E|��2���6n-�lm�;xh��o�L ��]�d�����W�$�!�
3}�K��Ȃ���Ip�<r�^���{����*&��:Α�p�>%�p.���u<�Ʉ>�x]��y���,��*(�$+2��.��VY���N^e͔w8q�Vdc�d��ؕw���{��yq��U���[���ۊ�X�&����#��*t�^��iLj��^^$K>~�I�X∞S���!pM�贈���\&L����F��CYģX�e�O�z.�U}�õ�����pذ��zE�`V��}�2����;Ǚ;/~"����,ơ�W1�]N�j�v�+��ji��_���2�u-��^K���7:n�5��F�[��;p�.-M!tTd��F����г�����j�$y�����0NT��O/k2�>����hSp��f� @A#�f�B���E6!��������0�5�Ih*Tɑ��+G�*��H1d�!Y�b�G_p�P�Ǥ)h&n��}�G�W]��ƃ"V����]�r��7�ԡ�c(��T�Gp�Aeؾ�u�0R����(˄��z��g����u���.�f��'O��$2�*����ք�þ�6�m����f�4
�z%(BN��IC6�h��eu�{eSۧmWG���0M؃���-�r������ü���,ݺ����U����$2]NH��-�`��,����S.�^�~���>Y�E/+
��@7dG��Ms~�w%�e'#;�X�9��<�=-%�����J_�O�ߓ��R�x�H�v(w��#h�f�D\ڗ����p�����nt�
�JE��)����?t�9��DdڱH5Y�H�#��<p����t(ٞn�a��2D�?#k�:*Q�P���pہ;X&[��u�9*ݴa�B�c�D�n�˭E�����	�ET/�'q�a�E]U�a^�̩-�8��}'\K7��}��"�[ɀ�0}�~��0=ys8���ĩ����ɒ����l+)�"��$?��X�$,a������#�ܕ:g����nj�U����V��a�t����lm��̧��i�������W�����U����O~����ן��;��ߥ���ƭ��6�l�������Ez�!EC�,:$E���!:ҒBTL3�@��c-Ƃ��D%*d�B4�B�l�Ļ��'��~�F?��>����	��=$~; � ~+@������.�I����w�^��F��[��r6�����/���o��O��t|�	�"����3`pʽD��.N9�k��h}�Rs��̘��$�\����|ٜ����IMr��y��Ê,N"���iSh4���R>^�!s�|�L��Ts�LO8*�Z�T���v�._n�r_eV�E>��X�5�#�g�8೼�N���� �;qm8��$=q��q�~qz

��RS�>���B�~9H����h�ons��,>��'ݽ���j2֤vr<4��U�r��P5U�b��\�Q�n�[�;O��*u2˙J=32]���Ӂ5���x6�apr�x�8�i�u�kv���E89svh���)�S�dK=���N6h�F5�D8�f��tu:<.sG�,�����	����&fFoO���������Ƣ*3�V������	S�������2G�Xg�¸Q�[6�E����V�8��r-�m>zhV�΀����s�)��I�JFE���=��♙~Q�T_-���/T*Sc�\P�T&6k�m�M��4�d;_K]���8�v�_'��k\�X����i74z���U��>����[�'�����`��ro�� �� ��3���4^�2�i����q�p�4z�NvA�R�ųZ��8���z�X8`҂TU��4#��$-T#��K�J�I�f���W���<Kg � ����f;I�wC��cY�J�|ܤ��,Ma�s�0*���`p2Te��E#�H�y%�c�� �xV����J�O�\9A��0H�:'�ڱLG�y�i���Zs;����5���8!�u�N�9�Bn&�i=5R܄�EFUpt�gKB@�%�Xd,��,������j�w��L8��
J�}]���Nj|T�*�xoN��f@�$��i��\��bN�����|�0[��Ҧ�����'��΀��t��� ��u��Rx�*�Hn�ƃ��&UYJ�٨���L�9=���RK
�A�(�*' �4�0��t�2Q�X�Ƞ��p�m�>�� ��<���4u���`ct@ �z�0���Jg�ۛO(1"q�I�[>9��왟<�ӱ"F�t,,S��0���''i��щ)3&d��Op�Q>�j!�ʩL��P	כ��!��h'�v��N��� u��y�{���{��o�"�!6�;��퍗6_E�����,Nx/^�=7�X	��C�@��V�Ⱔ��8#> ^�x��py�|g�ɷ���9�����/x�&���+�m�%��g#���-N"���o�!��77��q�x���=�w�y���?;W���H\X�|Ί��5S���Y!����x�����'鲃�8a0�$�\�r �}Os��"�4� ��������
��x9�X�l9>����(�經Ò��A,\��)6�
�A�kg��A��T�b�MZ�h3kڤY3�n̏�\GᆹC�. �⇃5 �B+5(qv����vf;q��XBF?�h:K��z��r��9{ ���ʑ<뗎2-�֭�T�&E��Qz� ��+��~}"�t�VQ�r�M�u�ܥUy�9������D�W�{ƌ�t�g�[�q��$������qn���2?��S�|�쌺��)�?|�����9���W���=t���u�#�*N%k��<�z�Y!ٟT�qvZ�K��RyW��e��w�}�{���t��PG���L8�/!�м'Y��H��qGPK�R�8c�F��f��iU�����7�r}(7��~��J^���ʠ����̕X-�$z��f�W�O
>e�1�2��T�Iu�jc0��S.�\'���;j{�itO���; ��p��D&w
�7Y�+e�����@<���L�P�e�Z]�r��8�67'M>��V*5(0�d��f��v?�U�T�m��lb���.���@��(3z47/��s��y�Lܼ���7o�8��-���7����K_'^�n^���7^�Lh�2_����"����ٴ�>#6܌����vse����P&�w�+���^�-�`�ݪ2����W7�ݧO�R�>}Jzy�^�yj�mW�u�p;���|��(����Hv�g��`4�Q�^?��f��hV��Pw�\{�L��;�k�I��U|�92p�m�/|��s�38�$�i�&����g�5>s-���x��w�|��2�6�B�s��_ 
������qs�w�����"kt�?�~�tn:�vȤ�n��B�R��B�� ��L�O"�03:��I�&aR�IC��.������-]WQ�/�]N��} ���5x��>���.��o퓏�_�vT���a	�`�,����b����w̺\��a�i������r����abM�^6��5]�������I]�C������x�	j9�����G*�`ѴP�1�b�058��4�8ӊ��n��UL��nv�����&h$��Ƽ�1^8�s�$9�4��H�HM�65
v9�,������ru ��r��VñU:���E��Sc�|�H�'���gq� ���������G���_����;�U}���em���>{e���s>j\�.Ԉ��^��	�Y�%=0����T7��&�s(X]�i��zӫdi�x�lR��s�4j`�AE'�����8�]lrO	 ߰d(��u���"���
Xj��B'�/�H|� ��� �\�����;Τ�]�@�V4�}�OK�� ���T���N?� �2���/��i�$;��2���G�����@�Nl*��FC�kND낖�28�Ļ�8��M�OC#ᐧ�5;�x� �+���HJuu'��q���й�Ɖ3�0����ς#�$�5S���&��aX�:W�Yő���j���)y��3���p�I��`�q��HtI��޾����LW� ��ف�[h_b��n��v_��N�*�P�noɽ���g�'�e�b��6�ͯ0@Q�X��d�'~�DKn�n�62��Be1�^�>4�����gi����J�� ���15,x
�o.��cKE���]�3;��`4XW$;��l
���q���0u��A�ml���vTm|f�N���M?]o�B�Ď���@��eCT�,i�₱݅�s��5;Ǣ$�sW���ز������G�n2�%Ă��V�n�>��~�F�'*�%"Kl����5v�!$�9@r��9n�}d �$6�![�x�c`����3}�
�Zj�C�\i��i��웸u��i*���~,.4��r���,�������Ҕ��� ��B��[�~�Mt���4ٚ�F��˞�W�+f�gǮ�>�y=���B$�_�"�������~]�?Ͽ�w��:ι�� �'��������ߵ<f�>�A� �PD�+Y�j�J���@訐o᳸o��D��(��]Y����}�W��^��6�t":�2��
�/L�<����+ZvRs�]���-ao��̝���+�=�~}���Lx���-Ō3��G$|��S�*��/V{=K��^��:�h�X
�����l�ŭ����Y���{���/}��g����>�m��m�q0��X��p§\��m�f��Y�c8��#p�&	��x�b}�fl�6�=���q���s���,��=1S�����~U�F�}�����V���h왡L2�ߟp�+��%a�g�pՔ�8K���B�R-U��R����&x�0�j(� ˦bY?��Ɂ={t���Z��(W埧��+��J�u�I�q���/J*�US�bF��9&�Q��ѧ`C��"xtSn�8d��k4���&4\�h0\6�iN]�����ڐ���~�ٙJ���)~=]/���ah�KW�	�1��g}z��gO�$��"�O�g[_<;�O�󎓽��S�'��w�,��T��<?�"6K�m鷊!ת�����w��(!�[{��6�;��G�p��w�;��C+��<u���S���w���v|k�j5�]o�Ѯ��~�������aE��>z��Ѻ�^�A�_�� (r��^��5�~�BCK�)��>d��jS*���5���r�.�Bh��~��K��׺�򟻻w*(�ٷ/��׏2�x�bu��D�s��I���9����+�)p�&O�dx2�<�I�#�^N:}��/�����%ơ~��nJĤt�ɫ��q/��K�hF>����1��d�iV��z*��	��q<�6���6r�O꿽I�=�������4�����s�{�I�`	�4����j����$������oe>*�ً"�����i�����4�h.`8�`��|��y�������Kǽ��?)<��I�ڟ��:�1��:��
�����8���i��O������� Y߇����ߣ�G^�?���o P��ߪ@��#�.���;�����RAj����������Y�Ï�A���I��=��Yw}�ø>�4K:,����8E��m�U��[#�?����������]��4�{��Je!P���"�ٱmX�Q������|�D7�%Rh5�K���ָ��*Y�~m��*��bq�/�:�d���S����[z�$}������״6���n�6�5i�;w,i+�;Z-s5�������cg�`�N����ꢲ��9C���g�����������(���� �O`	�
�?�����?f}��������B��OY�����=�� ��Ϝ�����Iy��S�q�Q�����9�����������IH�%������?)������ ��V�Ъ�N��ra��	�_��Hy��\��� �����r���U��J��C}h�ȃ�O����$	�x������?�U�)�8��5��_��pԌ����C&���.�/������L�g�����~ƥ���j?��t��*#��cu���Od\'p�+��xԃv��^e9@+h���u�Xv����@mʋI8��B�zSo����A�b��Z�2��%�����u���O�=u�%{=Y������iK{9Ez7t4�S̶�v��Jw6�K�ٺOi����h-vm%��Ȏ�&��0�4�U!XPR�r��U6���:�I3��m5צP�q�v�0��n=^i��o(H��s��B���A.�?���y��N����o�/����!g�*Q)#���I���@�	��@�	�����O��H���@�p@�F ��{�������?����������ë������������Fݵ�gM�O�5�9o������w�����;�>�[{]zޭG^�߯���[P��S�����D�κ�4���6]�X��a�ނ���V���*�A�K^�f�r��Sծ�r�k�f&c���z�_����z�\ �ig�~$J�H�����>�[����uu hԐ(D#y��݌b��s���.�R4В��0K
�Ǝd�͞G)Qlq��z|��F�4�T^��h~��[S�[�	��1ra��	��_ȃ�7���z����O��o�/�O	�����
r��^��Y�O㞋1�Gs�Cq4F��c>�p뺜�i3�K����.��$O:��A��w#�����:�������F��8��E�`�pr�Ձ�-�_ �QyT�;��)Iw��u��ٖ2[GlZt�W��^ZlpiQB��Jo5��j��;��3Rr�+a�e�Y�a��?���Ai���;��ʠ��V�a����������o�����_v��C�Of���O���f}7������e����m����hJa;kl`!���g��4Ǖ���F��ȥ-?�o.��R!��Ғ�:dmc27�¸)�� ������Q�8�� $��\n���~����а�ӈ�B�֮+�Qh�������X�I��f�<�����]��7�@��+;@��A��A�쿌�?`f�\�Gg��G�`�������h�̽�-��%I��ʹ�Vv2��]�J��e�����qf����|� rz�= ���lb����Zw$$Z�H��� B}۟SfS�Be='��|F��qo�Gj�"*j7�Z)�F�%�%����0[V��W`i��v䕴����z��F���MGAύ��WO�����%�:��� �fQ�t����@)�G�FohP%l��A�7Jۖ(;~X�n|�0E��N����A5�P��sB�>�łT���^G������s>�Ӏ+�J]R���i�͢�r������nW+��a�/��2g��e�Z��jE�#�G}k^m�%�&��\/S��RosQ�m�Ǎm��]h����?��K)����E��������S������������ �M��"-���?�� ��A���A�?[�'��3B:���Cێ�`�����O���۶�0��p>i;^�h��q�O�>n3���_�<��I���_��������E��N���C�h�i'50�-��:5���]��e�Ng(��e��>����Y��m!2�ٔ���4Zu����i{�b0�IMĞ�g�MYo6	��^I<�+6VU��!��������	� �7�����C֗	xi��G����4��g������R�ۛA�=� ��Ϛ�	�*��JH�������vp>���[�����W����_W���66�Y�(�=T,��v8WƓ�U��{�$�[�K��B�3���k�gr��l����(j����n�B�N��C^��.m8m'���xg5�ּ�e�ΰ��G���H�l܈�Ye�n����ښ�m�i����E$s�Ū���L�G)�Ri�FC��UB�\����m9�ߐ�-NW={Ê��#+�2���r1�|W���&}H��eʶ7�Yف�+MI�KT��DR�����gx�ͣ�Y���*�[�v3j�[�C5�h��O���7/Ε����γ��r�Ɔ{��٭g4M!�i٩!������������s
�������'p
�?#�����3���O��&1��� �C�7�C�7��������zB � ��{�y��������W���������'��/����/��f[��P�����RX�7a��Y_( i��G���T��'�����H�����aY�������?���
Y�?�Cd�������\8�����
��� �����3�:�������?�C��������?�� ����S8>�\�xB��?RA�?����o�/�O_� ���<�?����<��I��?�� �� ����/+��!����������f���8D�ȅ����@��C* �� ���v�?����T��/��������_.��f����O��H�Oy��!�?;@�?��C����
������ �/�����p=_�����������'��G��O��?Z�泌��\�#1���~ߥ��)��I�f8��\��\�X�wpֶy��h�6��)��"�O28����_3����GS���T>z��K�X�";�����Q�"j�!�����B���o�ړ�vR�}�`j����!	���Ja�i��9>m�-Z�T��� Tk���MzO'>�l���0��Ys>�4��Oخ���;"��?�E}0ץ{��ꢲ��9C����Y���	��f�<����e�\�?��d�<����?�n`�w��!��_v���_�%uzWXWQ�0�ȺP��RyT�f���"^ۭ��B��w�_����51(U-4��j�z��F��;16[��+�K��݈��,�Ů$,kK]�UIb��Fj�F^�F��B����X����C�7%�a�w���o�� ���_�꿠�꿠��?`�e�0���È��?�_����I�����o�-RjK+ffu��hˉA�����w�g�.6�d�'�J��'ہ�[4��E��/.Z��c~�PV��p��S�';��P-��kZ�/U�6��!��\3�F�H8���O���VfA(�ڰ�P/�#�ڶkww:��;���כE1���\X��R��N	:�j�@���25�(m[��p�a�����4P91:UҪ�����bWЕ���ٝ�\�>����8��Ե�n[�tW����f�J�qO��jv<��{��^0��/�`Q���$�h���e���[+�Y���<�t	xr�����X����_�/�'��?�$�����<�G���˟����x�i����%)��4��'������s*H��Ϻ���;���/��W�?�" ��^��I�����nl��Ŭ3d7:΋o`���\�ȿ[��(�E�C"�n�Σ�9�&?�W:A>��C/E���Ѿ��r�GJp�����.m].�K3]Ƒ�X�y([�n1p�"��xu�E1�꬛Yo�\MZBfb��Fk��T�WJ	/)�m����ʡ�X��D୮����?���YM4]��_��tM�-'�E6��o����[@6D@Q������$�����s��*�D��{��{�K���fb�5�D��D��p���l��.S��ٕw�����t���ք��B�������7���&����Ē���Xjܞ���*�l�S�� �Œ�pS!�+;�|�U��}�e��M�g�a1��i�p�P��%��)�1�Y��g���a��aՒ,��*�sd�zZ�a�C���� �{-��>��nO�y�~W�B�7�`�7'��(�@4��e�(��u���j�'����@��Nᵺ��(��	1�:���.Af�+�����
����ϓ��4�N�;��!��X���ߪ��!4�OH�����+W���%r%S+ ���x��?%���
��rA�J����rA�?���y��7������������S��S?������F�����+P��4���:����'�ǀ:!!ξ�����������_�������u����׻���n?�y~?���æ�F�ڑ)W��o4V
T'��t�Z�=���I�7����N��I��4C�1���hsz�y�r�@�dn?�~������S5��9,[36�*7�RT���-#Y�#?o7�����ӂ���gf�����#{�y3
_�z��b!�+��':�J���zn�D
o�������Fu���Si%�.u�!%�^��~�+ʠ����P�)'�1�*��A�4��Lò)?�L?�a��F��J�t�ZO���F	L�P"]���p���`������~����$�@D�N�P���:ԅ�ᶪ|���t�Q$�7�G���eK�Z�����{.�0��������?�:�g��>I��"����?U����O���?�?����\�_�r�A��2�?������+y����.���o��"���y�{�\V�E���U�˰$�=��k��݋��=������/�+]뿴����81�k�W����"*��	b��#������J8v����n�e�e�qY2Y	���5�ҩ���5tn]�b揇�ƍ�6uw���~��:/'�vZ-�ș6���R�~����h��N���C�ۆ�멣�czj�ybm#^$oQG	R�*R��i�[��E�!��m���;%���$���¥�+�a��u��]���Hƚz����>.Y��ao��JM�m�⤎nA;�J���M��a�Á"�LGݵ��7��Đ���h�yH�e���R��EGh��0?�i�)�k��HŘ�LbaX�ѵ��6�bC˧��|˟F�_�T��������U`�����������\������o�)P�5��o��A�7������߹p����������C��
A����������\ �?�����#���? ��*����_ѧ	��q�_b�c$���@)����� ��愜��&��� ��������_��sAa��B������Y��������?�Q8 ��/���;��0��y�,��B������A�G �@�P�����������P��B
��߶�+���� ����2B
C)��{�j������� �?��`�����Q8�����_)������?�QJa�߫� ��s�� �?����C�������o.(T�E������߶�+��w�?���\P�����?��/ ��������R�?��?�P��6�Q�	`�`��m�W���7�?������:����h4�$T��c���:fຩ.�ME����iju5]C�RG���ć赞ݟe��yk����|�����IjUZ��j��M�����Vv�z���?'B��D�|�b���3ȓRCx�8��P��*�ZUWy�a[�Ċ�H���&��u|��Ű�<W�*�����CG'k��KG�09Pev�Zg������ϊ�6�m�X4g�VoT_#| ;�콛�*���e�A���P���`ַ(����P��?šP����Cj}�,�����+?��cU����Ơ�M��@	ժ&u��Iײ�y��vqc���ë��&�޲��=M7d��<t6��A)oD��[����6k:�m�㥬�bu���r�������bh�m.RO����?��oA(t���=���_����_����/����迢�?@�R�?���$�y�������I���V6��ڨ�:qD�R�O�����>"�6؅�ښ�B��/�m�So�H���
� Do���;�9�LUm��i��J�,v�Vgf2�n�1�Щ�	�$�3��B�����2������u���Zi<��0�E�]���[ـ6<�<k��X��&+d-��*:NSH�,����}癳]��$}!t�rG�yƱ����J>��R��`�A�ө�lCEQot�fS�^=�����s&i��aN�I�X��$d��gء�8ܛ���;�d��ED�5*3�����)ʠ�P�*
�>�?n �=ʉ<������;�(������6�E ��������`L(�����r��	������,	��+�����������\P<�?i^��x� ���p�'n�?H�rA��T��y��������\ �?�������E)�z���rA��t�,�������?���?h�XJa�����������q��?�O�RL�{��a�������\��M��:�7�CO�c�GB�s?��
�e���s�G�cП���R?�g���:����ۻ��^����~���
{BMjGr�\僾�X)P����}kY��n�C$mެ:�_8-['��=
�$>,p&���i�5dˑy���B/�����Bw�~UM8y���ÌM��M���f�H����Í=e���Ĵ��y��33���L�Б=��	�����g=��Z��J�ǉ�ҽv�� �(l��a�Q]���TZ�8�Kw�G���o�aP
���C���I�/���߶�+�����P*�?^�<Q
��N�/��1��_�����k�`�� ��>5/�Z�E ��m�R�?��/e��;[ �+��?��/߳�y>��R�Q�N7��3#��ܵF������oX?|�?ID����uo����xMS�V ����9 �>�6��c������-Z�U&��,/Aoؑ�y�VUI�~C��Q�G�S��0�7�����P_�%�=!�� eI & ʒ ��0H�d�Hִ�V��0
*1{>^-mC$}Zn�I�U�FT���=R�Nb���u��Xn���^��+��34��j�U��f�?��b�B��7�_��ON(^�}l^��x� ����e��z[��rA���㔮�(�$U]�Ӫ��!f�F�J`&�!t� P�DT
1MB74�4�4�-I�C�Z�O�2����� �?����#jAܧ��|P'h""��U��d0�f�AO6�c׫�����q3���ު�A�
abu��B⚐;�j����2y���:��r�Dᴜ6�E2L3d�� >����@����?��Y���&PE_���2����+���S����&��X��x�(���8�H�/��ܩ�jh}Qf�%��W�+������Ŕ9��+۫�G�#���X<�j�|܅�m���ǡ0!fHmBiMl/�]�����@6➨�O���n���%nd�>���(���EP��@�㿮��š�_ ��0��/���@��� �W��h�BP�G5��
����4��I��m= ���o�XYM���oB�����1�G꿗� @�F Os �k+ک�@�[UU��CU�L�����TM_�cR|�Ck���4Ir8G�W�����<j����5QzQ�n{������s�e:�U���<�<�|�R+���2n2I��DF7ؤ�}�/ �K0PK��ƭ��E?k2-H������ь!	qǳHɗ/X.=��4J��b&��C|.��R���'�}Q8��ИՄ���M��:GMēo�+R���ѵǮ927�d���6�s�>ZGz=n������m��\X�r<�hm^G�r���I⍶s��C|x֘��Gp���1�N����W�?F��F��������c��Q�RF=�0�4v q����ό���ҟ��e�����}nL�5*��ӻ(1��ȉ*�7�8�Ŭ��ו����{��A�V|{������^wŅFz��G��;�/��r�,����%�|A_�~���$n�W=D�������$�E��Q$����/Xs|XS#��VN\���	��b��&�g%?�����1��/�(2��{c�~�7bCOW����}څ��������҉��l�b�j��6*�.�tK'L�ބG������}Y��IW�����Xf��0�����������*�{%H��t���+��;���Ƿ���/�ߕe�"\�Uޛ��ßo�p���k��v�*���'jz]�MXi#t��e����T�7��˕n�����~c^.}TI���;�UqSz?ރV�(���	y8b�#�#�ƣ_���a�K��ӌ� C�7�_~����P�F�յ��]�r)�r��1z%0�y؄���?/�n_�/�x���q��B$%�/�9�ܰ�����ב��g+o�k��^�''���Y�O<�7>�a�3�s�nCσ��Ad��(#�K��/)��ݳ.�*;��ڗ��8f���OOO_OoD�Q�`��Q0
F�(�.  ׼{�  