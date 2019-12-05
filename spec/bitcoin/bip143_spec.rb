require 'spec_helper'

describe 'BIP 143 spec', use_secp256k1: true do

  # https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki#Example

  describe 'Native P2WPKH' do
    it 'verify ecdsa signature' do
      tx = Bitcoin::Tx.parse_from_payload('0100000002fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f0000000000eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac11000000'.htb)

      script_pubkey0 = Bitcoin::Script.parse_from_payload('2103c9f4836b9a4f77fc0d81f7bcb01b7f1b35916864b9476c241ce9fc198bd25432ac'.htb)
      sig_hash0 = tx.sighash_for_input(0, script_pubkey0)

      key0 = Bitcoin::Key.new(priv_key: 'bbc27228ddcb9209d7fd6f36b02f7dfa6252af40bb2f1cbc7a557da8027ff866', key_type: Bitcoin::Key::TYPES[:p2pkh])
      sig0 = key0.sign(sig_hash0, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

      tx.inputs[0].script_sig = Bitcoin::Script.new << sig0

      script_pubkey1 = Bitcoin::Script.parse_from_payload('00141d0f172a0ecb48aee1be1f2687d2963ae33f71a1'.htb)
      sig_hash1 = tx.sighash_for_input(1, script_pubkey1, amount: 600000000,
                                       sig_version: :witness_v0)
      key1 = Bitcoin::Key.new(priv_key: '619c335025c7f4012e556c2a58b2506e30b8511b53ade95ea316fd8c3286feb9', key_type: Bitcoin::Key::TYPES[:p2wpkh])
      sig1 = key1.sign(sig_hash1, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

      tx.inputs[1].script_witness.stack << sig1
      tx.inputs[1].script_witness.stack << '025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee6357'.htb

      expect(tx.to_hex).to eq('01000000000102fff7f7881a8099afa6940d42d1e7f6362bec38171ea3edf433541db4e4ad969f00000000494830450221008b9d1dc26ba6a9cb62127b02742fa9d754cd3bebf337f7a55d114c8e5cdd30be022040529b194ba3f9281a99f2b1c0a19c0489bc22ede944ccf4ecbab4cc618ef3ed01eeffffffef51e1b804cc89d182d279655c3aa89e815b1b309fe287d9b2b55d57b90ec68a0100000000ffffffff02202cb206000000001976a9148280b37df378db99f66f85c95a783a76ac7a6d5988ac9093510d000000001976a9143bde42dbee7e4dbe6a21b2d50ce2f0167faa815988ac000247304402203609e17b84f6a7d30c80bfa610b5b4542f32a8a0d5447a12fb1366d7f01cc44a0220573a954c4518331561406f90300e8f3358f51928d43c212a8caed02de67eebee0121025476c2e83188368da1ff3e292e7acafcdb3566bb0ad253f62fc70f07aeee635711000000')

      expect(tx.verify_input_sig(0, script_pubkey0)).to be true
      expect(tx.verify_input_sig(1, script_pubkey1, amount: 600000000)).to be true
    end
  end

  describe 'P2SH-P2WPKH' do
    it 'verify ecdsa signature' do
      script_pubkey = Bitcoin::Script.parse_from_payload('a9144733f37cf4db86fbc2efed2500b4f4e49f31202387'.htb)
      redeem_script = Bitcoin::Script.parse_from_payload('001479091972186c449eb1ded22b78e40d009bdf0089'.htb)

      tx = Bitcoin::Tx.parse_from_payload('0100000001db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb66092ac4d3ceb1a54770100000000feffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac0008af2f000000001976a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac92040000'.htb)

      tx.inputs[0].script_sig = Bitcoin::Script.new << redeem_script.to_payload

      key = Bitcoin::Key.new(priv_key: 'eb696a065ef48a2192da5b28b694f87544b30fae8327c4510137a922f32c6dcf', key_type: Bitcoin::Key::TYPES[:p2wpkh_p2sh])
      sig_hash = tx.sighash_for_input(0, redeem_script, amount: 1000000000, sig_version: :witness_v0)
      sig = key.sign(sig_hash, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')

      tx.inputs[0].script_witness.stack << sig
      tx.inputs[0].script_witness.stack << '03ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48c43f7d6f93a2a26873'.htb

      expect(tx.to_hex).to eq('01000000000101db6b1b20aa0fd7b23880be2ecbd4a98130974cf4748fb66092ac4d3ceb1a5477010000001716001479091972186c449eb1ded22b78e40d009bdf0089feffffff02b8b4eb0b000000001976a914a457b684d7f0d539a46a45bbc043f35b59d0d96388ac0008af2f000000001976a914fd270b1ee6abcaea97fea7ad0402e8bd8ad6d77c88ac02473044022047ac8e878352d3ebbde1c94ce3a10d057c24175747116f8288e5d794d12d482f0220217f36a485cae903c713331d877c1f64677e3622ad4010726870540656fe9dcb012103ad1d8e89212f0b92c74d23bb710c00662ad1470198ac48c43f7d6f93a2a2687392040000')

      expect(tx.verify_input_sig(0, script_pubkey, amount: 1000000000)).to be true
    end
  end

  describe 'Native P2WSH' do
    it 'verify ecdsa signature' do
      witness_script = Bitcoin::Script.parse_from_payload('21026dccc749adc2a9d0d89497ac511f760f45c47dc5ed9cf352a58ac706453880aeadab210255a9626aebf5e29c0e6538428ba0d1dcf6ca98ffdf086aa8ced5e0d0215ea465ac'.htb)

      tx = Bitcoin::Tx.parse_from_payload('0100000002fe3dc9208094f3ffd12645477b3dc56f60ec4fa8e6f5d67c565d1c6b9216b36e0000000000ffffffff0815cf020f013ed6cf91d29f4202e8a58726b1ac6c79da47c23d1bee0a6925f80000000000ffffffff0100f2052a010000001976a914a30741f8145e5acadf23f751864167f32e0963f788ac00000000'.htb)

      script_pubkey0 = Bitcoin::Script.parse_from_payload('21036d5c20fa14fb2f635474c1dc4ef5909d4568e5569b79fc94d3448486e14685f8ac'.htb)
      sig_hash0 = tx.sighash_for_input(0, script_pubkey0)
      key0 = Bitcoin::Key.new(priv_key: 'b8f28a772fccbf9b4f58a4f027e07dc2e35e7cd80529975e292ea34f84c4580c', key_type: Bitcoin::Key::TYPES[:compressed])
      sig0 = key0.sign(sig_hash0, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
      tx.inputs[0].script_sig = Bitcoin::Script.new << sig0

      script_pubkey1 = Bitcoin::Script.parse_from_payload('00205d1b56b63d714eebe542309525f484b7e9d6f686b3781b6f61ef925d66d6f6a0'.htb)
      sig_hash1 = tx.sighash_for_input(1, witness_script, amount: 4900000000,
                                       hash_type: Bitcoin::SIGHASH_TYPE[:single], sig_version: :witness_v0)
      key1 = Bitcoin::Key.new(priv_key: '8e02b539b1500aa7c81cf3fed177448a546f19d2be416c0c61ff28e577d8d0cd', key_type: Bitcoin::Key::TYPES[:compressed])
      sig1 = key1.sign(sig_hash1, false) + [Bitcoin::SIGHASH_TYPE[:single]].pack('C')

      sig_hash2 = tx.sighash_for_input(1, witness_script, amount: 4900000000, skip_separator_index: 1,
                                       hash_type: Bitcoin::SIGHASH_TYPE[:single], sig_version: :witness_v0)
      key2 = Bitcoin::Key.new(priv_key: '86bf2ed75935a0cbef03b89d72034bb4c189d381037a5ac121a70016db8896ec', key_type: Bitcoin::Key::TYPES[:compressed])
      sig2 = key2.sign(sig_hash2, false) + [Bitcoin::SIGHASH_TYPE[:single]].pack('C')

      tx.inputs[1].script_witness.stack << sig2
      tx.inputs[1].script_witness.stack << sig1
      tx.inputs[1].script_witness.stack << witness_script.to_payload

      expect(tx.to_hex).to eq('01000000000102fe3dc9208094f3ffd12645477b3dc56f60ec4fa8e6f5d67c565d1c6b9216b36e000000004847304402200af4e47c9b9629dbecc21f73af989bdaa911f7e6f6c2e9394588a3aa68f81e9902204f3fcf6ade7e5abb1295b6774c8e0abd94ae62217367096bc02ee5e435b67da201ffffffff0815cf020f013ed6cf91d29f4202e8a58726b1ac6c79da47c23d1bee0a6925f80000000000ffffffff0100f2052a010000001976a914a30741f8145e5acadf23f751864167f32e0963f788ac000347304402200de66acf4527789bfda55fc5459e214fa6083f936b430a762c629656216805ac0220396f550692cd347171cbc1ef1f51e15282e837bb2b30860dc77c8f78bc8501e503473044022027dc95ad6b740fe5129e7e62a75dd00f291a2aeb1200b84b09d9e3789406b6c002201a9ecd315dd6a0e632ab20bbb98948bc0c6fb204f2c286963bb48517a7058e27034721026dccc749adc2a9d0d89497ac511f760f45c47dc5ed9cf352a58ac706453880aeadab210255a9626aebf5e29c0e6538428ba0d1dcf6ca98ffdf086aa8ced5e0d0215ea465ac00000000')

      expect(tx.verify_input_sig(0, script_pubkey0)).to be true
      expect(tx.verify_input_sig(1, script_pubkey1, amount: 4900000000)).to be true
    end
  end

  describe 'P2SH-P2WSH' do
    it 'verify ecdsa signature' do
      script_pubkey = Bitcoin::Script.parse_from_payload('a9149993a429037b5d912407a71c252019287b8d27a587'.htb)
      redeem_script = Bitcoin::Script.parse_from_payload('0020a16b5755f7f6f96dbd65f5f0d6ab9418b89af4b1f14a1bb8a09062c35f0dcb54'.htb)
      # 6-of-6 multisig
      witness_script = Bitcoin::Script.parse_from_payload('56210307b8ae49ac90a048e9b53357a2354b3334e9c8bee813ecb98e99a7e07e8c3ba32103b28f0c28bfab54554ae8c658ac5c3e0ce6e79ad336331f78c428dd43eea8449b21034b8113d703413d57761b8b9781957b8c0ac1dfe69f492580ca4195f50376ba4a21033400f6afecb833092a9a21cfdf1ed1376e58c5d1f47de74683123987e967a8f42103a6d48b1131e94ba04d9737d61acdaa1322008af9602b3b14862c07a1789aac162102d8b661b0b3302ee2f162b09e07a55ad5dfbe673a9f01d9f0c19617681024306b56ae'.htb)

      tx = Bitcoin::Tx.parse_from_payload('010000000136641869ca081e70f394c6948e8af409e18b619df2ed74aa106c1ca29787b96e0100000000ffffffff0200e9a435000000001976a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688acc0832f05000000001976a9147480a33f950689af511e6e84c138dbbd3c3ee41588ac00000000'.htb)
      tx.inputs[0].script_sig = Bitcoin::Script.new << redeem_script.to_payload

      tx.inputs[0].script_witness.stack << ''

      sig_hash0 = tx.sighash_for_input(0, witness_script, amount: 987654321, sig_version: :witness_v0)
      key0 = Bitcoin::Key.new(priv_key: '730fff80e1413068a05b57d6a58261f07551163369787f349438ea38ca80fac6', key_type: Bitcoin::Key::TYPES[:compressed])
      sig0 = key0.sign(sig_hash0, false) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
      expect(sig0.bth).to eq('304402206ac44d672dac41f9b00e28f4df20c52eeb087207e8d758d76d92c6fab3b73e2b0220367750dbbe19290069cba53d096f44530e4f98acaa594810388cf7409a1870ce01')
      tx.inputs[0].script_witness.stack << sig0

      sig_hash1 = tx.sighash_for_input(0, witness_script, amount: 987654321,
                                       sig_version: :witness_v0, hash_type: Bitcoin::SIGHASH_TYPE[:none])
      key1 = Bitcoin::Key.new(priv_key: '11fa3d25a17cbc22b29c44a484ba552b5a53149d106d3d853e22fdd05a2d8bb3', key_type: Bitcoin::Key::TYPES[:compressed])
      sig1 = key1.sign(sig_hash1, false) + [Bitcoin::SIGHASH_TYPE[:none]].pack('C')
      expect(sig1.bth).to eq('3044022068c7946a43232757cbdf9176f009a928e1cd9a1a8c212f15c1e11ac9f2925d9002205b75f937ff2f9f3c1246e547e54f62e027f64eefa2695578cc6432cdabce271502')
      tx.inputs[0].script_witness.stack << sig1

      sig_hash2 = tx.sighash_for_input(0, witness_script, amount: 987654321,
                                       sig_version: :witness_v0, hash_type: Bitcoin::SIGHASH_TYPE[:single])
      key2 = Bitcoin::Key.new(priv_key: '77bf4141a87d55bdd7f3cd0bdccf6e9e642935fec45f2f30047be7b799120661', key_type: Bitcoin::Key::TYPES[:compressed])
      sig2 = key2.sign(sig_hash2, false) + [Bitcoin::SIGHASH_TYPE[:single]].pack('C')
      expect(sig2.bth).to eq('3044022059ebf56d98010a932cf8ecfec54c48e6139ed6adb0728c09cbe1e4fa0915302e022007cd986c8fa870ff5d2b3a89139c9fe7e499259875357e20fcbb15571c76795403')
      tx.inputs[0].script_witness.stack << sig2

      sig_hash3 = tx.sighash_for_input(0, witness_script, amount: 987654321,
                                       sig_version: :witness_v0, hash_type: (Bitcoin::SIGHASH_TYPE[:all] | Bitcoin::SIGHASH_TYPE[:anyonecanpay]))
      key3 = Bitcoin::Key.new(priv_key: '14af36970f5025ea3e8b5542c0f8ebe7763e674838d08808896b63c3351ffe49', key_type: Bitcoin::Key::TYPES[:compressed])
      sig3 = key3.sign(sig_hash3, false) + [Bitcoin::SIGHASH_TYPE[:all] | Bitcoin::SIGHASH_TYPE[:anyonecanpay]].pack('C')
      expect(sig3.bth).to eq('3045022100fbefd94bd0a488d50b79102b5dad4ab6ced30c4069f1eaa69a4b5a763414067e02203156c6a5c9cf88f91265f5a942e96213afae16d83321c8b31bb342142a14d16381')
      tx.inputs[0].script_witness.stack << sig3

      sig_hash4 = tx.sighash_for_input(0, witness_script, amount: 987654321,
                                       sig_version: :witness_v0, hash_type: (Bitcoin::SIGHASH_TYPE[:none] | Bitcoin::SIGHASH_TYPE[:anyonecanpay]))
      key4 = Bitcoin::Key.new(priv_key: 'fe9a95c19eef81dde2b95c1284ef39be497d128e2aa46916fb02d552485e0323', key_type: Bitcoin::Key::TYPES[:compressed])
      sig4 = key4.sign(sig_hash4, false) + [Bitcoin::SIGHASH_TYPE[:none] | Bitcoin::SIGHASH_TYPE[:anyonecanpay]].pack('C')
      expect(sig4.bth).to eq('3045022100a5263ea0553ba89221984bd7f0b13613db16e7a70c549a86de0cc0444141a407022005c360ef0ae5a5d4f9f2f87a56c1546cc8268cab08c73501d6b3be2e1e1a8a0882')
      tx.inputs[0].script_witness.stack << sig4

      sig_hash5 = tx.sighash_for_input(0, witness_script, amount: 987654321,
                                       sig_version: :witness_v0, hash_type: (Bitcoin::SIGHASH_TYPE[:single] | Bitcoin::SIGHASH_TYPE[:anyonecanpay]))
      key5 = Bitcoin::Key.new(priv_key: '428a7aee9f0c2af0cd19af3cf1c78149951ea528726989b2e83e4778d2c3f890', key_type: Bitcoin::Key::TYPES[:compressed])
      sig5 = key5.sign(sig_hash5, false) + [Bitcoin::SIGHASH_TYPE[:single] | Bitcoin::SIGHASH_TYPE[:anyonecanpay]].pack('C')
      expect(sig5.bth).to eq('30440220525406a1482936d5a21888260dc165497a90a15669636d8edca6b9fe490d309c022032af0c646a34a44d1f4576bf6a4a74b67940f8faa84c7df9abe12a01a11e2b4783')
      tx.inputs[0].script_witness.stack << sig5

      tx.inputs[0].script_witness.stack << witness_script.to_payload

      expect(tx.to_hex).to eq('0100000000010136641869ca081e70f394c6948e8af409e18b619df2ed74aa106c1ca29787b96e0100000023220020a16b5755f7f6f96dbd65f5f0d6ab9418b89af4b1f14a1bb8a09062c35f0dcb54ffffffff0200e9a435000000001976a914389ffce9cd9ae88dcc0631e88a821ffdbe9bfe2688acc0832f05000000001976a9147480a33f950689af511e6e84c138dbbd3c3ee41588ac080047304402206ac44d672dac41f9b00e28f4df20c52eeb087207e8d758d76d92c6fab3b73e2b0220367750dbbe19290069cba53d096f44530e4f98acaa594810388cf7409a1870ce01473044022068c7946a43232757cbdf9176f009a928e1cd9a1a8c212f15c1e11ac9f2925d9002205b75f937ff2f9f3c1246e547e54f62e027f64eefa2695578cc6432cdabce271502473044022059ebf56d98010a932cf8ecfec54c48e6139ed6adb0728c09cbe1e4fa0915302e022007cd986c8fa870ff5d2b3a89139c9fe7e499259875357e20fcbb15571c76795403483045022100fbefd94bd0a488d50b79102b5dad4ab6ced30c4069f1eaa69a4b5a763414067e02203156c6a5c9cf88f91265f5a942e96213afae16d83321c8b31bb342142a14d16381483045022100a5263ea0553ba89221984bd7f0b13613db16e7a70c549a86de0cc0444141a407022005c360ef0ae5a5d4f9f2f87a56c1546cc8268cab08c73501d6b3be2e1e1a8a08824730440220525406a1482936d5a21888260dc165497a90a15669636d8edca6b9fe490d309c022032af0c646a34a44d1f4576bf6a4a74b67940f8faa84c7df9abe12a01a11e2b4783cf56210307b8ae49ac90a048e9b53357a2354b3334e9c8bee813ecb98e99a7e07e8c3ba32103b28f0c28bfab54554ae8c658ac5c3e0ce6e79ad336331f78c428dd43eea8449b21034b8113d703413d57761b8b9781957b8c0ac1dfe69f492580ca4195f50376ba4a21033400f6afecb833092a9a21cfdf1ed1376e58c5d1f47de74683123987e967a8f42103a6d48b1131e94ba04d9737d61acdaa1322008af9602b3b14862c07a1789aac162102d8b661b0b3302ee2f162b09e07a55ad5dfbe673a9f01d9f0c19617681024306b56ae00000000')
      expect(tx.verify_input_sig(0, script_pubkey, amount: 987654321))
    end
  end

end