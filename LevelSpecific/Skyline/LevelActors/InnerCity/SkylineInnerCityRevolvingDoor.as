class ASkylineInnerCityRevolvingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UBoxComponent BoxComp1;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UBoxComponent BoxComp2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		if(BoxComp1.IsOverlappingActor(Game::Mio) || BoxComp1.IsOverlappingActor(Game::Zoe) || BoxComp2.IsOverlappingActor(Game::Mio) || BoxComp2.IsOverlappingActor(Game::Zoe))
		{
			ForceComp.AddDisabler(this);
			BPStopped();
			UInnerCityRevolvingDoorEffectEventHandler::Trigger_Stopped(this);
		}else{
			ForceComp.RemoveDisabler(this);
			BPStart();
			UInnerCityRevolvingDoorEffectEventHandler::Trigger_Start(this);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BPStart()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BPStopped()
	{
	}
}

class UInnerCityRevolvingDoorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Stopped() {}
	UFUNCTION(BlueprintEvent)
	void Start() {}

};