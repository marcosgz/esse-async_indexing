# frozen_string_literal: true

RSpec.shared_context "with venues index definition" do
  let(:restaurant) do
    {id: 1, name: "Gourmet Paradise"}
  end
  let(:hotel) do
    {id: 2, name: "Hotel California"}
  end
  let(:auditorium) do
    {id: 3, name: "Parco della Musica"}
  end
  let(:venues) do
    [restaurant, hotel, auditorium]
  end
  let(:total_venues) { venues.size }

  before do
    # closure for the stub_index block
    ds = venues
    stub_esse_index(:venues) do
      repository :venue, const: false do
        collection do |**context, &block|
          filtered = ds
          if context.key?(:id)
            filtered = ds.select { |venue| venue[:id] == context[:id] }
          end
          block.call(filtered, **context) unless filtered.empty?
        end
        document do |venue, **context|
          {
            _id: venue[:id],
            name: venue[:name]
          }
        end
      end
    end
  end
end
