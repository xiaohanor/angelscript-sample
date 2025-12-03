class AIslandOverseerDoorAcid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AHazeActor Owner;
	UIslandOverseerSettings OverseerSettings;
	private float CurrentRadius = 0;
	TArray<AHazeActor> HitTargets;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverseerSettings = UIslandOverseerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentRadius += OverseerSettings.DoorAcidExpansionSpeed * DeltaTime;
		// Debug::DrawDebugCylinder(ActorLocation, ActorLocation, CurrentRadius, 32, FLinearColor::Green, OverseerSettings.DoorAcidDamageWidth * 2);

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			if(HitTargets.Contains(CurPlayer))
				continue;
			
			FCollisionShape Shape = FCollisionShape();
			Shape.SetSphere(OverseerSettings.DoorAcidDamageWidth - 25);
			
			FVector TransformDir = (CurPlayer.ActorLocation - ActorLocation).GetSafeNormal().VectorPlaneProject(ActorUpVector);
			FTransform Transform;
			Transform.SetLocation(ActorLocation + TransformDir * CurrentRadius);

			bool bDamagePlayer = Overlap::QueryShapeOverlap(CurPlayer.CapsuleComponent.GetCollisionShape(), CurPlayer.CapsuleComponent.WorldTransform, Shape, Transform);
			if (bDamagePlayer && CurPlayer.HasControl())
			{
				CurPlayer.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(), DamageEffect, DeathEffect);
				HitTargets.Add(CurPlayer);
			}
		}

		if(CurrentRadius > OverseerSettings.DoorAcidMaximumRadius)
			AddActorDisable(this);
	}
}