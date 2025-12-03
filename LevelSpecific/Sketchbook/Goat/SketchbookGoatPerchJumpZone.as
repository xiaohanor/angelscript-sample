class ASketchbookGoatPerchJumpZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent JumpZoneVolume;

	UPROPERTY(EditInstanceOnly)
	TArray<ASketchbookGoatPerchPoint> JumpPoints;

	UPROPERTY(EditInstanceOnly)
	bool bIsBackwards = false;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JumpZoneVolume.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		JumpZoneVolume.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		USketchbookGoatPlayerComponent GoatComp = USketchbookGoatPlayerComponent::Get(OtherActor);
		
		if(GoatComp != nullptr && GoatComp.MountedGoat != nullptr)
		{
			GoatComp.MountedGoat.JumpZone = this;
			GoatComp.MountedGoat.bPerchJumping = false;
		}
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		USketchbookGoatPlayerComponent GoatComp = USketchbookGoatPlayerComponent::Get(OtherActor);

		if(GoatComp != nullptr && GoatComp.MountedGoat != nullptr)
		{
			GoatComp.MountedGoat.JumpZone = nullptr;
		}
	}
};