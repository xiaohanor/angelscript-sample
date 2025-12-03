
UCLASS(Abstract)
class AHackablePortal : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshSphere;	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent BoxTrigger;	

	UPROPERTY(EditAnywhere)
	AHackablePortal OtherPortalActor;
	UPROPERTY(DefaultComponent)
	USceneComponent TeleportLocation;
	UPROPERTY(DefaultComponent)
	USceneComponent POILocation;
	

	bool bPortalActive = false;
	UPROPERTY(EditAnywhere)
	float Timer = 6.0;
	float TimerTemp = 6.0;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFX;
	UPROPERTY(EditAnywhere)
	bool bAlwaysActive = false;

	UPROPERTY(EditAnywhere)
	bool bGiveImpulsOnExit = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"onTriggerOverlapp");
		if(bAlwaysActive == false)
			MeshSphere.SetHiddenInGame(true);

		if(bAlwaysActive)
		{

		}
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bPortalActive)
		{
			TimerTemp -= DeltaSeconds;
			if(TimerTemp <= 0)
			{
				DeactivatePortal();
				bPortalActive = false;
			}
		}
	}


	UFUNCTION()
	void ActivatePortal()
	{
		TimerTemp = Timer;
		OtherPortalActor.TimerTemp = OtherPortalActor.Timer;

		if(bPortalActive)
			return;

		MeshSphere.SetHiddenInGame(false);
		VFX.Activate();

		TArray<AActor> Overlaps;
		GetOverlappingActors(Overlaps, AHazeActor);

		for (auto Actor : Overlaps)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
			if (Player !=nullptr)
			{	
				TeleportPlayer(Player);
			}
		}

		bPortalActive = true;
		OtherPortalActor.ActivatePortal();
	}

	UFUNCTION()
	void DeactivatePortal()
	{
		MeshSphere.SetHiddenInGame(true);
		VFX.Deactivate();
	}

	UFUNCTION(NotBlueprintCallable)
	void onTriggerOverlapp(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
										UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(!bPortalActive && bAlwaysActive == false)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		TeleportPlayer(Player);
	}
	UFUNCTION()
	void TeleportPlayer(AHazePlayerCharacter Player)
	{
		Player.SetActorLocation(OtherPortalActor.TeleportLocation.GetWorldLocation());
		Player.SetActorRotation(OtherPortalActor.TeleportLocation.GetWorldRotation());

		auto Poi = Player.CreatePointOfInterest();
		Poi.FocusTarget.SetFocusToComponent(OtherPortalActor.POILocation);
		Poi.Settings.Duration = 0.05;
		Poi.Apply(this, 0);

		if(bGiveImpulsOnExit)
			Player.AddMovementImpulse(OtherPortalActor.TeleportLocation.GetForwardVector() * 4000 + Player.GetActorUpVector() * 380);
	}
}
