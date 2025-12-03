class AIslandOverseerTremor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshContainer;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	AHazeActor Owner;
	UIslandOverseerSettings OverseerSettings;
	private float CurrentRadius = 0;
	TArray<AHazeActor> HitTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverseerSettings = UIslandOverseerSettings::GetSettings(Owner);
		CurrentRadius = OverseerSettings.TremorMinimumRadius;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentRadius += OverseerSettings.TremorExpansionSpeed * DeltaTime;
		// Debug::DrawDebugCylinder(ActorLocation, ActorLocation, CurrentRadius, 32, FLinearColor::Yellow, OverseerSettings.TremorDamageWidth * 2);

		float Scale = CurrentRadius * 0.00195;
		MeshContainer.WorldScale3D = FVector(Scale, Scale, 1);

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			if(HitTargets.Contains(CurPlayer))
				continue;
			
			FCollisionShape Shape = FCollisionShape();
			Shape.SetSphere(OverseerSettings.TremorDamageWidth - 25);
			
			FVector TransformDir = (CurPlayer.ActorLocation - ActorLocation).GetSafeNormal().VectorPlaneProject(ActorUpVector);
			FTransform Transform;
			Transform.SetLocation(ActorLocation + TransformDir * CurrentRadius);

			bool bDamagePlayer = Overlap::QueryShapeOverlap(CurPlayer.CapsuleComponent.GetCollisionShape(), CurPlayer.CapsuleComponent.WorldTransform, Shape, Transform);
			if (bDamagePlayer && CurPlayer.HasControl())
			{
				CurPlayer.DamagePlayerHealth(0.5, DamageEffect = DamageEffect, DeathEffect = DeathEffect);
				HitTargets.Add(CurPlayer);
			}
		}

		if(CurrentRadius > OverseerSettings.TremorMaximumRadius)
			AddActorDisable(this);
	}
}