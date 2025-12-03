class ASketchbookSplineRespawn : AHazeActor
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Respawn")
    AHazeActor SplineActor;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
			SetActorLocation(SplineActor.GetActorLocation());
	}

	bool bHasBeenActivated = false;

	UFUNCTION(BlueprintCallable)
    void ActivateRespawn(AHazePlayerCharacter Player)
    {
		if(!HasControl())
			return;

		if(bHasBeenActivated)
			return;

		CrumbActivateRespawn();
    }

	UFUNCTION(CrumbFunction)
	void CrumbActivateRespawn()
	{
		for(auto ItPlayer : Game::Players)
		{
			DeactivateRespawn(ItPlayer);
			FOnRespawnOverride RespawnOverride;
			RespawnOverride.BindUFunction(this, n"HandleRespawn");
			ItPlayer.ApplyRespawnPointOverrideDelegate(ItPlayer, RespawnOverride);
		}

		bHasBeenActivated = true;
	}

	UFUNCTION(BlueprintCallable)
    void DeactivateRespawn(AHazePlayerCharacter Player)
    {
		Player.ClearRespawnPointOverride(Player);
    }

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		UHazeSplineComponent SplineComp = Spline::GetGameplaySpline(SplineActor);
		if (SplineComp == nullptr)
		{
			devError("No spline specified to respawn on for RespawnOnSplineNearOtherPlayerVolume");
			return false;
		}

		OutLocation.RespawnPoint = nullptr;
		OutLocation.RespawnRelativeTo = nullptr;
		OutLocation.RespawnTransform = SplineComp.GetClosestSplineWorldTransformToWorldLocation(Player.OtherPlayer.ActorLocation);
		OutLocation.RespawnTransform.SetRotation(FRotator::MakeFromZY(OutLocation.RespawnTransform.Rotation.UpVector, -OutLocation.RespawnTransform.Rotation.RightVector));

		if(Sketchbook::IsLocationOffScreen(Player, OutLocation.RespawnTransform.Location))
		{
			// if(UPlayerRespawnComponent::Get(Player).StickyRespawnPoint != nullptr)
			// {
			// 	OutLocation.RespawnTransform = UPlayerRespawnComponent::Get(Player).StickyRespawnPoint.ActorTransform;
			// }

			return false;
		}

		return true;
	}
}