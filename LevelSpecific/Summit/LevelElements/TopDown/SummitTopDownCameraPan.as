class ASummitTopDownCameraPan : AHazeActor
{

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;
	default Collision.SetCollisionProfileName(n"OverlapAllDynamic");

	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor Camera;
	AHazeCameraActor ParentCamera;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION()
	bool TeleportedRecently(AHazePlayerCharacter Player)
	{
		auto Comp = UTeleportResponseComponent::Get(Player);
		return Comp.HasTeleportedWithinFrameWindow(10);
	}
}