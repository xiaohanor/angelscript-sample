UCLASS(Abstract)
class APrisonBeamElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UCapsuleComponent BottomTrigger;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UCapsuleComponent TopTrigger;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UNiagaraComponent EffectComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence Anim;

	UPROPERTY(EditAnywhere)
	float Height = 1800.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TopTrigger.SetRelativeLocation(FVector(0.0, 0.0, Height));

		EffectComp.SetNiagaraVariableVec3("BeamEnd", FVector(Height + 400.0, 0.0, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BottomTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterBottomTrigger");
		TopTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTopTrigger");
	}

	UFUNCTION()
	private void EnterBottomTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPrisonBeamElevatorPlayerComponent PlayerComp = UPrisonBeamElevatorPlayerComponent::Get(Player);
		PlayerComp.bGoingUp = true;
		PlayerComp.CurrentElevator = this;
	}

	UFUNCTION()
	private void EnterTopTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor,  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPrisonBeamElevatorPlayerComponent PlayerComp = UPrisonBeamElevatorPlayerComponent::Get(Player);
		PlayerComp.bGoingUp = false;
		PlayerComp.CurrentElevator = this;
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeamPlayer(bool bUp) {}
}