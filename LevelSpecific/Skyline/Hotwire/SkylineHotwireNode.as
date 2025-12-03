class ASkylineHotwireNode : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (AttachParentActor != nullptr)
		{
			auto Hotwire = Cast<ASkylineHotwire>(AttachParentActor);
			if (Hotwire != nullptr)
			{
				FVector Direction;
				ActorRelativeLocation = Hotwire.GetProjectedPointOnCylinder(ActorRelativeLocation, Direction);
				ActorQuat = FQuat::MakeFromZ(Direction);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Activate()
	{
		bIsActivated = true;
		BP_Activate();
	}

	void Deactivate()
	{
		bIsActivated = false;
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() { }

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() { }
};