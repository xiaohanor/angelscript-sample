UCLASS(Abstract)
class ASkylineCleanerBot : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineCleanerBotMoveCapability");

	UPROPERTY(DefaultComponent)
	UPerchPointComponent PerchPoint;

	UPROPERTY(DefaultComponent, Attach=CharacterMesh0)
	USceneComponent WeaponPivot;

	UPROPERTY()
	UNiagaraSystem WeaponFireFx;

	UPROPERTY(DefaultComponent)
	USceneComponent MainBrush;

	UPROPERTY(DefaultComponent, Attach=MainBrush)
	USceneComponent Brush;

	UPROPERTY(DefaultComponent,Attach=MainBrush)
	USceneComponent Brush2;

	UPROPERTY(DefaultComponent,Attach=MainBrush)
	USceneComponent Brush3;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent PerchSystem;

	UPROPERTY(DefaultComponent, Attach=MeshOffsetComponent)
	UStaticMeshComponent BodyMesh;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface AngryEyes;

	UMaterialInterface DefaultEyes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		PerchPoint.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartedPerch");
		PerchPoint.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"StoppedPerch");
		DefaultEyes = BodyMesh.GetMaterial(0);
	}

	UFUNCTION()
	private void StartedPerch(AHazePlayerCharacter Player, UPerchPointComponent _PerchPoint)
	{
		USkylineCleanerBotEventHandler::Trigger_OnPerchStarted(this, FSkylineCleanerBotEventData(Player));
		PerchSystem.Activate();
	}

	UFUNCTION()
	private void StoppedPerch(AHazePlayerCharacter Player, UPerchPointComponent _PerchPoint)
	{
		PerchSystem.Deactivate();
		USkylineCleanerBotEventHandler::Trigger_OnPerchStopped(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MainBrush.AddRelativeRotation(FRotator(0, 1, 0) * DeltaSeconds * 100);
		Brush.AddRelativeRotation(FRotator(0, 1, 0) * DeltaSeconds * 200);
		Brush2.AddRelativeRotation(FRotator(0, 1, 0) * DeltaSeconds * 250);
		Brush3.AddRelativeRotation(FRotator(0, 1, 0) * DeltaSeconds * 300);
	}
}