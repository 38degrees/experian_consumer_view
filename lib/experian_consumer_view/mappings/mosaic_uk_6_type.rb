module ExperianConsumerView
  module Mappings
    class MosaicUk6Type
      CODE_MAP = {
        '01' => { api_code: '01', code: 'A01', description: 'World-Class Wealth' },
        '02' => { api_code: '02', code: 'A02', description: 'Uptown Elite' },
        '03' => { api_code: '03', code: 'A03', description: 'Penthouse Chic' },
        '04' => { api_code: '04', code: 'A04', description: 'Metro High-Flyers' },
        '05' => { api_code: '05', code: 'B05', description: 'Premium Fortunes' },
        '06' => { api_code: '06', code: 'B06', description: 'Diamond Days' },
        '07' => { api_code: '07', code: 'B07', description: 'Alpha Families' },
        '08' => { api_code: '08', code: 'B08', description: 'Bank of Mum and Dad' },
        '09' => { api_code: '09', code: 'B09', description: 'Empty-Nest Adventure' },
        '10' => { api_code: '10', code: 'C10', description: 'Wealthy Landowners' },
        '11' => { api_code: '11', code: 'C11', description: 'Rural Vogue' },
        '12' => { api_code: '12', code: 'C12', description: 'Scattered Homesteads' },
        '13' => { api_code: '13', code: 'C13', description: 'Village Retirement' },
        '14' => { api_code: '14', code: 'D14', description: 'Satellite Settlers' },
        '15' => { api_code: '15', code: 'D15', description: 'Local Focus' },
        '16' => { api_code: '16', code: 'D16', description: 'Outlying Seniors' },
        '17' => { api_code: '17', code: 'D17', description: 'Far-Flung Outposts' },
        '18' => { api_code: '18', code: 'E18', description: 'Legacy Elders' },
        '19' => { api_code: '19', code: 'E19', description: 'Bungalow Haven' },
        '20' => { api_code: '20', code: 'E20', description: 'Classic Grandparents' },
        '21' => { api_code: '21', code: 'E21', description: 'Solo Retirees' },
        '22' => { api_code: '22', code: 'F22', description: 'Boomerang Boarders' },
        '23' => { api_code: '23', code: 'F23', description: 'Family Ties' },
        '24' => { api_code: '24', code: 'F24', description: 'Fledgling Free' },
        '25' => { api_code: '25', code: 'F25', description: 'Dependable Me' },
        '26' => { api_code: '26', code: 'G26', description: 'Cafés and Catchments' },
        '27' => { api_code: '27', code: 'G27', description: 'Thriving Independence' },
        '28' => { api_code: '28', code: 'G28', description: 'Modern Parents' },
        '29' => { api_code: '29', code: 'G29', description: 'Mid-Career Convention' },
        '30' => { api_code: '30', code: 'H30', description: 'Primary Ambitions' },
        '31' => { api_code: '31', code: 'H31', description: 'Affordable Fringe' },
        '32' => { api_code: '32', code: 'H32', description: 'First-Rung Futures' },
        '33' => { api_code: '33', code: 'H33', description: 'Contemporary Starts' },
        '34' => { api_code: '34', code: 'H34', description: 'New Foundations' },
        '35' => { api_code: '35', code: 'H35', description: 'Flying Solo' },
        '36' => { api_code: '36', code: 'I36', description: 'Solid Economy' },
        '37' => { api_code: '37', code: 'I37', description: 'Budget Generations' },
        '38' => { api_code: '38', code: 'I38', description: 'Economical Families' },
        '39' => { api_code: '39', code: 'I39', description: 'Families on a Budget' },
        '40' => { api_code: '40', code: 'J40', description: 'Value Rentals' },
        '41' => { api_code: '41', code: 'J41', description: 'Youthful Endeavours' },
        '42' => { api_code: '42', code: 'J42', description: 'Midlife Renters' },
        '43' => { api_code: '43', code: 'J43', description: 'Renting Rooms' },
        '44' => { api_code: '44', code: 'K44', description: 'Inner City Stalwarts' },
        '45' => { api_code: '45', code: 'K45', description: 'City Diversity' },
        '46' => { api_code: '46', code: 'K46', description: 'High Rise Residents' },
        '47' => { api_code: '47', code: 'K47', description: 'Single Essentials' },
        '48' => { api_code: '48', code: 'K48', description: 'Mature Workers' },
        '49' => { api_code: '49', code: 'L49', description: 'Flatlet Seniors' },
        '50' => { api_code: '50', code: 'L50', description: 'Pocket Pensions' },
        '51' => { api_code: '51', code: 'L51', description: 'Retirement Communities' },
        '52' => { api_code: '52', code: 'L52', description: 'Estate Veterans' },
        '53' => { api_code: '53', code: 'L53', description: 'Seasoned Survivors' },
        '54' => { api_code: '54', code: 'M54', description: 'Down-to-Earth Owners' },
        '55' => { api_code: '55', code: 'M55', description: 'Back with the Folks' },
        '56' => { api_code: '56', code: 'M56', description: 'Self Supporters' },
        '57' => { api_code: '57', code: 'N57', description: 'Community Elders' },
        '58' => { api_code: '58', code: 'N58', description: 'Culture & Comfort' },
        '59' => { api_code: '59', code: 'N59', description: 'Large Family Living' },
        '60' => { api_code: '60', code: 'N60', description: 'Ageing Access' },
        '61' => { api_code: '61', code: 'O61', description: 'Career Builders' },
        '62' => { api_code: '62', code: 'O62', description: 'Central Pulse' },
        '63' => { api_code: '63', code: 'O63', description: 'Flexible Workforce' },
        '64' => { api_code: '64', code: 'O64', description: 'Bus-Route Renters' },
        '65' => { api_code: '65', code: 'O65', description: 'Learners & Earners' },
        '66' => { api_code: '66', code: 'O66', description: 'Student Scene' },
        '99' => { api_code: '99', code: 'U', description: 'Unclassified' }
      }.freeze
    end
  end
end
