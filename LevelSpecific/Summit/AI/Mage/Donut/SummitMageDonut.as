class ASummitMageDonut : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AHazeActor Owner;
	USummitMageSettings MageSettings;
	private float CurrentRadius = 0;
	TArray<AHazeActor> HitTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MageSettings = USummitMageSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentRadius += MageSettings.DonutExpansionSpeed * DeltaTime;
		Debug::DrawDebugCylinder(ActorCenterLocation, ActorCenterLocation + FVector(0, 0, 50), CurrentRadius, 16, FLinearColor::Red, MageSettings.DonutDamageWidth * 2);
		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			if(HitTargets.Contains(CurPlayer))
				continue;
			auto DragonComp = UPlayerTeenDragonComponent::Get(CurPlayer);
			if(DragonComp == nullptr)
				continue;
			
			bool bDamagePlayer = false;
			float HorizontalDistance = GetHorizontalDistanceTo(CurPlayer);
			float VerticalDistance = Math::Abs(ActorUpVector.DotProduct(ActorLocation - CurPlayer.ActorCenterLocation));

			//Debug::DrawDebugSphere(DragonComp.TeenDragon.ActorCenterLocation);

			if (HorizontalDistance > CurrentRadius - MageSettings.DonutDamageWidth && HorizontalDistance < CurrentRadius + MageSettings.DonutDamageWidth)
				bDamagePlayer = true;
			if (VerticalDistance >= MageSettings.DonutDamageWidth)
				bDamagePlayer = false;
			if (bDamagePlayer && CurPlayer.HasControl())
			{
				FTeenDragonStumble Stumble;
				Stumble.Duration = 0.5;
				FVector Dir = (CurPlayer.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
				Dir.Z = 0.75;
				Stumble.Move = Dir * 750;
				Stumble.Apply(CurPlayer);
				CurPlayer.SetActorRotation((-Stumble.Move).ToOrientationQuat());
				CurPlayer.DamagePlayerHealth(0.4);
				HitTargets.Add(CurPlayer);
			}
		}

		if(CurrentRadius > MageSettings.DonutMaximumRadius)
			DestroyActor();
	}
}