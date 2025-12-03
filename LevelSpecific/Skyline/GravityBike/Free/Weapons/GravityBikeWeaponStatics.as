namespace GravityBikeWeapon
{
	UFUNCTION()
	void ChargeGravityBikeWeapon()
	{
		for(auto Player : Game::Players)
		{
			auto WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
			if(WeaponComp == nullptr)
				continue;

			WeaponComp.AddCharge(1.0);
		}
	}
}