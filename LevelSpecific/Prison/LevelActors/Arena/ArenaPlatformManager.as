class AArenaPlatformManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(5.0);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditInstanceOnly)
	TArray<AArenaPlatform> FrontPlatforms;

	UPROPERTY(EditInstanceOnly)
	AArenaPlatformFrontRoot FrontRoot;

	UPROPERTY(EditInstanceOnly)
	TArray<AArenaPlatform> BackPlatforms;

	AArenaPlatform CurrentMioPlatform;
	AArenaPlatform CurrentZoePlatform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AArenaPlatform> Platforms;
		for (AArenaPlatform CurPlatform : Platforms)
		{
			CurPlatform.OnPlayerLanded.AddUFunction(this, n"PlayerLandedOnPlatform");
		}

		CurrentMioPlatform = Platforms[0];
		CurrentZoePlatform = Platforms[0];
	}

	UFUNCTION()
	private void PlayerLandedOnPlatform(AArenaPlatform Platform, AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			CurrentMioPlatform = Platform;
		else if (Player.IsZoe())
			CurrentZoePlatform = Platform;
	}

	AArenaPlatform GetCurrentPlayerPlatform(AHazePlayerCharacter Player)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(Player.ActorCenterLocation, Player.ActorCenterLocation - (FVector::UpVector * 800.0));
		if (Hit.bBlockingHit)
		{
			AArenaPlatform Platform = Cast<AArenaPlatform>(Hit.Actor);
			if (Platform != nullptr)
			{
				if (Player.IsMio())
					CurrentMioPlatform = Platform;
				else if (Player.IsZoe())
					CurrentZoePlatform = Platform;
			}
		}

		if (Player.IsMio() && CurrentMioPlatform != nullptr)
			return CurrentMioPlatform;
		else if (Player.IsZoe() && CurrentZoePlatform != nullptr)
			return CurrentZoePlatform;

		return nullptr;
	}

	UFUNCTION(DevFunction)
	void SetBackPlatformsDestroyed()
	{
		for (AArenaPlatform Platform : BackPlatforms)
		{
			Platform.SetDestroyed();
		}
	}

	UFUNCTION()
	void AttackFrontPlatformsToFrontRoot()
	{
		for (AArenaPlatform Platform : FrontPlatforms)
		{
			Platform.AttachToActor(FrontRoot, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION()
	void DetachFrontPlatformsFromFrontRoot()
	{
		for (AArenaPlatform Platform : FrontPlatforms)
		{
			Platform.DetachFromActor(EDetachmentRule::KeepWorld);
		}
	}
}