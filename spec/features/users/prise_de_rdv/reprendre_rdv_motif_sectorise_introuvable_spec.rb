RSpec.describe "Reprendre RDV depuis le lien d'annulation, motif sectorisé au niveau agent" do
  let!(:territory) { create(:territory, departement_number: "26") }
  let!(:organisation) { create(:organisation, territory:) }
  let!(:lieu) { create(:lieu, organisation:) }
  let!(:motif) { create(:motif, :sectorisation_level_agent, organisation:) }

  let!(:sector) { create(:sector, territory:, name: "Secteur agent", human_id: "secteur-agent") }
  let!(:zone) { create(:zone, sector:) }

  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:attribution) { create(:sector_attribution, :level_agent, sector:, organisation:, agent:) }
  let!(:plage_ouverture) do
    create(:plage_ouverture, organisation:, lieu:, agent:, motifs: [motif],
                             first_day: Time.zone.today + 1.day, start_time: Tod::TimeOfDay.new(9), end_time: Tod::TimeOfDay.new(9, 45))
  end

  let!(:user) { create(:user, last_name: "Dupont") }
  let!(:rdv) { create(:rdv, organisation:, motif:, lieu:, users: [user], status: "revoked", cancelled_at: Time.zone.now) }
  let!(:token) { rdv.participations.first.restricted_auth_token }

  it "propose le créneau disponible de l'agent rattaché au secteur" do
    # Bug connu : le lien ne transmet ni city_code ni street_ban_id, donc Users::GeoSearch#available_motifs
    # ne retrouve jamais un motif sectorisé au niveau agent (ou organisation), même quand l'agent est bien
    # rattaché au secteur. L'usager tombe sur "aucun créneau trouvé" au lieu de pouvoir reprendre son RDV.
    visit reprendre_rdv_from_participation_invitation_token_short_path(tkn: token)

    fill_in "3 premières lettres de votre nom", with: "DUP"
    click_on "Valider"

    expect(page).to have_content("09:00")
  end
end
