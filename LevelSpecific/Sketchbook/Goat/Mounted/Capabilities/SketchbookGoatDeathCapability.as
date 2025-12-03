class USketchbookGoatDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	ASketchbookGoat Goat;
	USketchbookGoatSplineMovementComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Goat = Cast<ASketchbookGoat>(Owner);
		SplineComp = USketchbookGoatSplineMovementComponent::Get(Goat);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Goat.IsMounted())
			return false;

		if(!ShouldBeDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Goat.IsMounted())
			return true;

		if(!ShouldBeDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Goat.JumpZone = nullptr;
		Goat.bPerchJumping = false;
		Goat.AddActorVisualsBlock(this);
		Goat.AddActorCollisionBlock(this);

		Goat.BlockCapabilities(Sketchbook::Goat::Tags::SketchbookGoat, this);

		Goat.bIsDead = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Goat.RemoveActorVisualsBlock(this);
		Goat.RemoveActorCollisionBlock(this);

		Goat.UnblockCapabilities(Sketchbook::Goat::Tags::SketchbookGoat, this);

		Goat.bIsDead = false;

		Goat.MoveComp.Reset();

		auto OtherGoat = Goat.GetOtherGoat();
		if(OtherGoat != nullptr)
		{
			Goat.SetActorVelocity(OtherGoat.ActorVelocity.VectorPlaneProject(SplineComp.GetWorldUp()));
		}
	}

	bool ShouldBeDead() const
	{
		if(Goat.MountedPlayer.IsPlayerRespawning())
			return true;

		if(Goat.MountedPlayer.IsPlayerDead())
			return true;

		return false;
	}
};