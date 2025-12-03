class AMeltdownBossPhaseOneSlapAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftTarget;
	default LeftTarget.RelativeLocation = FVector(0, 1200, 0);

	UPROPERTY(DefaultComponent)
	USceneComponent RightTarget;
	default RightTarget.RelativeLocation = FVector(0, -1200, 0);

	UPROPERTY(DefaultComponent, Attach = LeftTarget)
	USceneComponent LeftTelegraph;
	default LeftTelegraph.RelativeLocation = FVector(0, 0, 600);

	UPROPERTY(DefaultComponent, Attach = RightTarget)
	USceneComponent RightTelegraph;
	default RightTelegraph.RelativeLocation = FVector(0, 0, 600);

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = LeftTarget)
	UEditorBillboardComponent LeftBillboard;
	UPROPERTY(DefaultComponent, Attach = RightTarget)
	UEditorBillboardComponent RightBillboard;
#endif

	UPROPERTY(EditAnywhere)
	int SlapCount = 6;
	UPROPERTY(EditAnywhere)
	float Interval = 1.2;
	UPROPERTY(EditAnywhere)
	float ShockwaveSpeed = 800.0;
	UPROPERTY(EditAnywhere)
	float ShockwaveMaxRadius = 4000.0;
	UPROPERTY(EditAnywhere)
	float ShockwaveWidth = 100.0;
	UPROPERTY(EditAnywhere)
	FVector ShockwaveDisplacement = FVector(0, 0, 200);

	private float Timer = 0.0;
	private int Remaining = 0;
	private bool bNextIsLeft = false;

	private FVector LeftTelegraphStart;
	private FVector RightTelegraphStart;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		LeftTelegraphStart = LeftTelegraph.RelativeLocation;
		RightTelegraphStart = RightTelegraph.RelativeLocation;
	}

	UFUNCTION(DevFunction)
	void StartAttack()
	{
		RemoveActorDisable(this);

		Remaining = SlapCount;
		Timer = 0.0;
		bNextIsLeft = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer >= Interval)
		{
			Timer -= Interval;

			AMeltdownBossPhaseOneShockwave Shockwave = AMeltdownBossPhaseOneShockwave::Spawn(
				bNextIsLeft ? LeftTarget.WorldLocation : RightTarget.WorldLocation
			);
			Shockwave.Speed = ShockwaveSpeed;
			Shockwave.MaxRadius = ShockwaveMaxRadius;
			Shockwave.Width = ShockwaveWidth;
			Shockwave.Displacement = ShockwaveDisplacement;
			Shockwave.bAutoDestroy = true;
			Shockwave.ActivateShockwave();

			Remaining -= 1;
			bNextIsLeft = !bNextIsLeft;
			if (Remaining <= 0)
				AddActorDisable(this);
		}

		float Alpha = Timer / Interval;
		float DownAlpha = Math::GetMappedRangeValueClamped(
			FVector2D(0.9, 1.0),
			FVector2D(0.0, 1.0),
			Alpha
		);

		float UpAlpha = 1.0 - Math::GetMappedRangeValueClamped(
			FVector2D(0.0, 0.1),
			FVector2D(0.0, 1.0),
			Alpha
		);

		LeftTelegraph.RelativeLocation = Math::Lerp(
			LeftTelegraphStart, FVector(LeftTelegraphStart.X, LeftTelegraphStart.Y, 0.0),
			bNextIsLeft ? DownAlpha : UpAlpha,
		);

		RightTelegraph.RelativeLocation = Math::Lerp(
			RightTelegraphStart, FVector(RightTelegraphStart.X, RightTelegraphStart.Y, 0.0),
			!bNextIsLeft ? DownAlpha : UpAlpha,
		);
	}
};