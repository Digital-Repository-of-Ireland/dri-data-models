describe DRI::Metadata::Transformations do

  context 'spatial transformations' do

    it 'should parse a DCMI point' do
      point = 'name=Raheenapisha; east=-7.2859979; north=52.615355;'
      results = described_class.transform_geospatial({ geographic_coverage: [point]})

      expect(results[:name]).to include('Raheenapisha')
      expect(results[:coords]).to eq(["-7.2859979 52.615355"])
    end

    it 'should parse a DCMI box' do
      box = "name=Ireland, West of; northlimit=54.492377 ; eastlimit=-7.95496 ; southlimit=52.973868 ; westlimit=-10.338993"
      results = described_class.transform_geospatial({ geographic_coverage: [box]})

      expect(results[:name]).to include('Ireland, West of')
      expect(results[:coords]).to eq(["ENVELOPE(-10.338993, -7.95496, 54.492377, 52.973868)"])
    end

    it 'should accept ING points' do
      point = "east=248405; north=151775; projection=ING"
      allow(DRI::Metadata::Transformations::SpatialTransformations).to receive(:giqtrans).and_return("-7.286100444881164 52.615465407942516")

      results = described_class.transform_geospatial({ geographic_coverage: [point]})
      expect(results[:coords]).to eq(["-7.286100444881164 52.615465407942516"])
    end

    it 'should accept ITM points' do
      point = "east=648345; north=651820; projection=ITM"
      allow(DRI::Metadata::Transformations::SpatialTransformations).to receive(:giqtrans).and_return("-7.2860995621042877 52.61546963259449")

      results = described_class.transform_geospatial({ geographic_coverage: [point]})
      expect(results[:coords]).to eq(["-7.2860995621042877 52.61546963259449"])
    end
  end

  context 'name transformations' do
  
    it 'should transform names to human readable' do
      expect(described_class.transform_name(['Lewis, Daniel, Day-', 'Valera, Eamon, de'])).to eq (['Daniel Day-Lewis','Eamon de Valera'])
    end
  end
end
