namespace GravityBikeFree
{
	UFUNCTION(BlueprintPure)
	void GetGravityBikes(AGravityBikeFree&out MioGravityBike, AGravityBikeFree&out ZoeGravityBike)
	{
		MioGravityBike = GravityBikeFree::GetGravityBike(Game::Mio);
		ZoeGravityBike = GravityBikeFree::GetGravityBike(Game::Zoe);
	}

	UFUNCTION(BlueprintPure)
	AGravityBikeFree GetGravityBike(const AHazePlayerCharacter Player)
	{
		check(Player != nullptr);
		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		if(!ensure(DriverComp != nullptr))
			return nullptr;

		return DriverComp.GetOrSpawnGravityBike();
	}

	UFUNCTION(BlueprintPure)
	AGravityBikeFree GetMioGravityBike()
	{
		return GravityBikeFree::GetGravityBike(Game::Mio);
	}

	UFUNCTION(BlueprintPure)
	AGravityBikeFree GetZoeGravityBike()
	{
		return GravityBikeFree::GetGravityBike(Game::Zoe);
	}

	/**
	 * To simplify the setup process, we use our own function for teleport to respawn point
	 */
	UFUNCTION(BlueprintCallable)
	void TeleportGravityBikesToRespawnPoint(ARespawnPoint RespawnPoint, FInstigator Instigator, bool bIncludeCamera = true)
	{
		check(RespawnPoint != nullptr);

		for(auto Player : Game::Players)
		{
			Player.TeleportToRespawnPoint(RespawnPoint, Instigator, bIncludeCamera);
			AGravityBikeFree GravityBike = GravityBikeFree::GetGravityBike(Player);
			GravityBike.SnapToTransform(FTransform(Player.ActorQuat, Player.ActorLocation));

			auto CameraUserComp = UCameraUserComponent::Get(Player);
			CameraUserComp.SnapCamera(GravityBike.ActorForwardVector);

			auto CameraDataComp = UGravityBikeFreeCameraDataComponent::Get(Player);
			CameraDataComp.Reset();
		}
	}
};

mixin AGravityBikeFree GetOtherBike(const AGravityBikeFree GravityBike)
{
	return GravityBikeFree::GetGravityBike(GravityBike.GetDriver().OtherPlayer);
}