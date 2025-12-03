class ASkylineDeathBoundsCylinder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;
#endif

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere)
	float Radius = 3000.0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugCircle(
			ActorLocation, Radius, 24, FLinearColor::Red,
			10.0, ActorRightVector, ActorUpVector);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (IsOutsideBounds(Player.ActorLocation))
			{
				Player.KillPlayer(DeathEffect = DeathEffect);
			}
		}
	}

	bool IsOutsideBounds(FVector Location) const
	{
		FVector PositionOnLine = Math::ProjectPositionOnInfiniteLine(ActorLocation, ActorForwardVector, Location);
		if (Location.DistSquared(PositionOnLine) > Radius * Radius)
			return true;

//		Debug::DrawDebugPoint(PositionOnLine, 100.0, FLinearColor::Green, 0.0);
//		Debug::DrawDebugCircle(PositionOnLine, Radius, 24, FLinearColor::Red, 10.0, SourceTransform.Rotation.RightVector, SourceTransform.Rotation.UpVector);

		return false;
	}
};