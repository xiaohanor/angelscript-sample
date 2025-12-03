enum ESanctuaryLavamoleGeyserState
{
	Inactive,
	Anticipate,
	Rising,
	Decreasing,
}

class ASanctuaryLavamoleGeyser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffsetter;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetter)
	UCapsuleComponent LavaOverlapper;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.bOverlapMesh = false;
	default LavaComp.bOverlapTrigger = true;
	default LavaComp.DamagePerSecond = 0.5;
	default LavaComp.DamageDuration = 0.2;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UNiagaraComponent LavaBubbles;
	ESanctuaryLavamoleGeyserState State;

	FHazeAcceleratedFloat AccHeight;
	float OGHeight = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGHeight = MeshOffsetter.RelativeLocation.Z;

		TArray<UActorComponent> VFXs;
		GetAllComponents(UNiagaraComponent, VFXs);
		if (VFXs.Num() > 0)
		{
			LavaBubbles = Cast<UNiagaraComponent>(VFXs[0]);
			LavaBubbles.Deactivate();
		}
		AccHeight.SnapTo(OGHeight);
	}

	void StartGeyser()
	{
		State = ESanctuaryLavamoleGeyserState::Anticipate;
		if (LavaBubbles != nullptr)
			LavaBubbles.Activate();
		ActionQueue.Idle(3.0);
		ActionQueue.Event(this, n"Rise");
		ActionQueue.Idle(2.0);
		ActionQueue.Event(this, n"Decrease");
		ActionQueue.Idle(2.0);
		ActionQueue.Event(this, n"Deactivate");
	}

	UFUNCTION()
	private void Rise()
	{
		State = ESanctuaryLavamoleGeyserState::Rising;
	}

	UFUNCTION()
	private void Decrease()
	{
		State = ESanctuaryLavamoleGeyserState::Decreasing;
		if (LavaBubbles != nullptr)
			LavaBubbles.Deactivate();
	}

	UFUNCTION()
	private void Deactivate()
	{
		State = ESanctuaryLavamoleGeyserState::Inactive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (State == ESanctuaryLavamoleGeyserState::Rising)
			AccHeight.SpringTo(0.0, 50.0, 0.4, DeltaSeconds);
		else
			AccHeight.AccelerateTo(OGHeight, 1.3, DeltaSeconds);

		FVector Location = FVector::ZeroVector;
		Location.Z = AccHeight.Value;
		MeshOffsetter.SetRelativeLocation(Location);
	}
};