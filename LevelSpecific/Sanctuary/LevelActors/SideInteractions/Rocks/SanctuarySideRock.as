class ASanctuarySideRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxTranslationComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslationComp)
	UStaticMeshComponent ThingMesh;

	UPROPERTY(DefaultComponent, Attach = FauxTranslationComp)
	UPerchPointComponent PerchComp;
	default PerchComp.bAllowGrappleToPoint = false;
	default PerchComp.ActivationRange = 450.0;

	UPROPERTY(DefaultComponent, Attach = PerchComp)
	UPerchEnterByZoneComponent EnterZone;

	const float MaxAllowedZDistance = 200.0;
	const float PlayerHitForce = 200.0;

	const float AvoidPlayerDistance = 1500.0;
	const float AvoidPlayerForce = 500.0;

	AHazePlayerCharacter PerchingPlayer = nullptr;

	UPROPERTY(EditInstanceOnly)
	bool bAvoiding = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartPerch");
		PerchComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"StoppedPerch");

	}

	UFUNCTION()
	private void StartPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchingPlayer = Player;
		FVector TowardsOrigin = (ActorLocation - FauxTranslationComp.WorldLocation).GetClampedToSize(0.0, MaxAllowedZDistance);
		float ForceAlpha = Math::Clamp(TowardsOrigin.Size() / MaxAllowedZDistance, 0.0, 1.0);
		FauxTranslationComp.ApplyImpulse(FauxTranslationComp.WorldLocation, -FVector::UpVector * Math::EaseInOut(1.0, 0.0, ForceAlpha, 2.0) * PlayerHitForce);
	}

	UFUNCTION()
	private void StoppedPerch(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		PerchingPlayer = nullptr;
		FauxTranslationComp.ApplyImpulse(FauxTranslationComp.WorldLocation, FVector::UpVector * 10.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector TowardsOrigin = ActorLocation - FauxTranslationComp.WorldLocation;
		if (TowardsOrigin.Size() > KINDA_SMALL_NUMBER)
			FauxTranslationComp.ApplyForce(FauxTranslationComp.WorldLocation, TowardsOrigin);

		if (PerchingPlayer != Game::Mio)
		{
			FVector ToMio = Game::Mio.ActorLocation - FauxTranslationComp.WorldLocation;
			if (ToMio.Size() < AvoidPlayerDistance)
			{
				float MioCloseAlpha = 1.0 - Math::Clamp(ToMio.Size() / AvoidPlayerDistance, 0.0, 1.0);
				float Sign = bAvoiding ? -1.0 : 1.0;
				FauxTranslationComp.ApplyForce(FauxTranslationComp.WorldLocation, ToMio.GetSafeNormal() * Sign * Math::EaseIn(0.0, AvoidPlayerForce, MioCloseAlpha, 2.0));
			}
		}
		if (PerchingPlayer != Game::Zoe)
		{
			FVector ToZoe = Game::Zoe.ActorLocation - FauxTranslationComp.WorldLocation;
			if (ToZoe.Size() < AvoidPlayerDistance)
			{
				float ZoeCloseAlpha = 1.0 - Math::Clamp(ToZoe.Size() / AvoidPlayerDistance, 0.0, 1.0);
				float Sign = bAvoiding ? -1.0 : 1.0;
				FauxTranslationComp.ApplyForce(FauxTranslationComp.WorldLocation, ToZoe.GetSafeNormal() * Sign * Math::EaseIn(0.0, AvoidPlayerForce, ZoeCloseAlpha, 2.0));
			}
		}
	}
};