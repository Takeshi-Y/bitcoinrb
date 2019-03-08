require 'spec_helper'
require 'tmpdir'
require 'fileutils'

describe Bitcoin::Store::SPVChain do

  let (:chain) { create_test_chain }
  after { chain.db.close }

  describe '#find_entry_by_hash' do
    subject { chain.find_entry_by_hash(target) }

    let(:next_header) do
      Bitcoin::BlockHeader.parse_from_payload(
        '0100000043497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea3309' \
        '00000000bac8b0fa927c0ac8234287e33c5f74d38d354820e24756ad709d7038' \
        'fc5f31f020e7494dffff001d03e4b672'.htb
      )
    end
    let(:target) {'06128e87be8b1b4dea47a7247d5528d2702c96826c7a648497e773b800000000' }

    before do
      chain.append_header(next_header)
    end

    it 'return correct ChainEntry' do
      expect(subject.header).to eq next_header
      expect(subject.height).to eq 1
    end

    context 'header is not stored' do
      let(:target) {'0000000000000000000000000000000000000000000000000000000000000000' }

      it { expect(subject).to be_nil }
    end
  end

  describe '#append_header' do
    subject { chain }

    context 'correct header' do
      it 'should store data' do
        genesis = subject.latest_block
        expect(genesis.height).to eq(0)
        expect(genesis.header).to eq(Bitcoin.chain_params.genesis_block.header)
        expect(subject.next_hash('43497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000')).to be nil

        next_header = Bitcoin::BlockHeader.parse_from_payload('0100000043497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000bac8b0fa927c0ac8234287e33c5f74d38d354820e24756ad709d7038fc5f31f020e7494dffff001d03e4b672'.htb)
        subject.append_header(next_header)

        block = subject.latest_block
        expect(block.height).to eq(1)
        expect(block.header).to eq(next_header)
        expect(subject.next_hash('43497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000')).to eq('06128e87be8b1b4dea47a7247d5528d2702c96826c7a648497e773b800000000')
      end
    end

    context 'invalid header' do
      it 'should raise error' do
        # pow is invalid
        next_header = Bitcoin::BlockHeader.parse_from_payload('0100000043497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000bac8b0fa927c0ac8234287e33c5f74d38d354820e24756ad709d7038fc5f31f020e7494dffff001d03e4b672'.htb)
        next_header.nonce = 1
        expect{subject.append_header(next_header)}.to raise_error(StandardError)

        # previous hash mismatch
        next_header = Bitcoin::BlockHeader.parse_from_payload('0100000006128e87be8b1b4dea47a7247d5528d2702c96826c7a648497e773b800000000e241352e3bec0a95a6217e10c3abb54adfa05abb12c126695595580fb92e222032e7494dffff001d00d23534'.htb)
        expect{subject.append_header(next_header)}.to raise_error(StandardError)
      end
    end

    context 'duplicate header' do
      it 'should not raise error' do
        # add block 1, 2
        header1 = Bitcoin::BlockHeader.parse_from_payload('0100000043497fd7f826957108f4a30fd9cec3aeba79972084e90ead01ea330900000000bac8b0fa927c0ac8234287e33c5f74d38d354820e24756ad709d7038fc5f31f020e7494dffff001d03e4b672'.htb)
        header2 = Bitcoin::BlockHeader.parse_from_payload('0100000006128e87be8b1b4dea47a7247d5528d2702c96826c7a648497e773b800000000e241352e3bec0a95a6217e10c3abb54adfa05abb12c126695595580fb92e222032e7494dffff001d00d23534'.htb)
        subject.append_header(header1)
        subject.append_header(header2)

        # add duplicate header 1
        expect{subject.append_header(header1)}.not_to raise_error
        expect(subject.latest_block.header).to eq(header2)
      end
    end
  end

end
