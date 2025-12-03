UCLASS(Abstract)
class AVillagePerchWaterWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WheelRoot;

	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	USceneComponent PerchRoot1;

	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	USceneComponent PerchRoot2;

	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	USceneComponent PerchRoot3;

	UPROPERTY(DefaultComponent, Attach = WheelRoot)
	USceneComponent PerchRoot4;

	UPROPERTY(DefaultComponent, Attach = PerchRoot1)
	UPerchPointComponent PerchPointComp1;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp1)
	UPerchEnterByZoneComponent PerchLandingComp1;

	UPROPERTY(DefaultComponent, Attach = PerchRoot2)
	UPerchPointComponent PerchPointComp2;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp2)
	UPerchEnterByZoneComponent PerchLandingComp2;

	UPROPERTY(DefaultComponent, Attach = PerchRoot3)
	UPerchPointComponent PerchPointComp3;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp3)
	UPerchEnterByZoneComponent PerchLandingComp3;

	UPROPERTY(DefaultComponent, Attach = PerchRoot4)
	UPerchPointComponent PerchPointComp4;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp4)
	UPerchEnterByZoneComponent PerchLandingComp4;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxKillComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleKillComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	float RotSpeed = 45.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ProximityCamShakeClass;
	TPerPlayer<UCameraShakeBase> CamShakeInstance;
	float CamShakeInnerRadius = 1100.0;
	float CamShakeOuterRadius = 2600.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> PerchRoots;
		PerchRoots.Add(PerchRoot1);
		PerchRoots.Add(PerchRoot2);
		PerchRoots.Add(PerchRoot3);
		PerchRoots.Add(PerchRoot4);

		for (USceneComponent PerchRoot : PerchRoots)
		{
			FRotator OriginalRotation = PerchRoot.WorldRotation;
			PerchRoot.SetAbsolute(false, true, false);
			PerchRoot.SetWorldRotation(OriginalRotation);
		}

		CapsuleKillComp.OnComponentBeginOverlap.AddUFunction(this, n"EnterCapsuleKillTrigger");
		BoxKillComp.OnComponentBeginOverlap.AddUFunction(this, n"EnterBoxKillTrigger");
	}

	UFUNCTION()
	private void EnterCapsuleKillTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!BoxKillComp.IsOverlappingActor(Player))
			return;

		FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(ActorForwardVector).GetSafeNormal();
		Player.KillPlayer(FPlayerDeathDamageParams(DeathDir), DeathEffect);
	}

	UFUNCTION()
	private void EnterBoxKillTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!CapsuleKillComp.IsOverlappingActor(Player))
			return;

		FVector DeathDir = (Player.ActorLocation - ActorLocation).ConstrainToPlane(ActorRightVector).GetSafeNormal();
		Player.KillPlayer(FPlayerDeathDamageParams(DeathDir), DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		WheelRoot.AddLocalRotation(FRotator(0.0, 0.0, RotSpeed * DeltaTime));

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			float Dist = WheelRoot.WorldLocation.Distance(Player.ActorLocation);
			if (Dist <= CamShakeOuterRadius)
			{
				if (CamShakeInstance[Player] == nullptr)
				{
					CamShakeInstance[Player] = Player.PlayCameraShake(ProximityCamShakeClass, this);
				}

				float ShakeScale = Math::GetMappedRangeValueClamped(FVector2D(CamShakeOuterRadius, CamShakeInnerRadius), FVector2D(0.0, 1.0), Dist);
				CamShakeInstance[Player].ShakeScale = ShakeScale;

				float FFStrength = Math::Lerp(0.0, 0.1, ShakeScale);
				float LeftFF = Math::Sin(Time::GetGameTimeSeconds() * 10.0) * FFStrength;
				float RightFF = Math::Sin(-Time::GetGameTimeSeconds() * 10.0) * FFStrength;
				Player.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
			}
			else
			{
				if (CamShakeInstance[Player] != nullptr)
				{
					Player.StopCameraShakeInstance(CamShakeInstance[Player]);
					CamShakeInstance[Player] = nullptr;
				}
			}
		}
	}
}