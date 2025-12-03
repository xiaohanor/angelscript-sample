namespace EggPath
{
	const FName EggPlaceCancelPromptInstigator = n"EggPlaced";
	UFUNCTION()
	ASummitEggStoneBeast GetStoneBeast()
	{
		return TListedActors<ASummitEggStoneBeast>().Single;
	}

	UFUNCTION()
	void ActivateStoneBeastState(ESummitEggBeastState State)
	{
		auto StoneBeast = TListedActors<ASummitEggStoneBeast>().Single;
		StoneBeast.ActivateStoneBeast(State);
	}

	UFUNCTION()
	void StoneBeastShootAtLocation(FVector Location, bool bDestroyProjectileWhenReachEnd, float MoveDuration = 2)
	{
		auto StoneBeast = TListedActors<ASummitEggStoneBeast>().Single;
		FTransform StartTransform = StoneBeast.SkelMesh.GetBoneTransform(StoneBeast.ShootBone);
		StoneBeast.ShootProjectile(StartTransform, Location, bDestroyProjectileWhenReachEnd, MoveDuration);
	}

	UFUNCTION()
	void StoneBeastShootAtPlayer(AHazePlayerCharacter Player, bool bDestroyProjectileWhenReachEnd, float MoveDuration = 2)
	{
		auto StoneBeast = TListedActors<ASummitEggStoneBeast>().Single;
		FTransform StartTransform = StoneBeast.SkelMesh.GetBoneTransform(StoneBeast.ShootBone);
		StoneBeast.ShootProjectile(StartTransform, Player.ActorLocation, bDestroyProjectileWhenReachEnd, MoveDuration);
	}

	UFUNCTION()
	void ForceResetEggs()
	{
		USummitEggBackpackComponent::Get(Game::Mio).bExternalPickupRequested = true;
		USummitEggBackpackComponent::Get(Game::Zoe).bExternalPickupRequested = true;
		Game::Mio.RemoveCancelPromptByInstigator(EggPlaceCancelPromptInstigator);
		Game::Zoe.RemoveCancelPromptByInstigator(EggPlaceCancelPromptInstigator);
	}
}