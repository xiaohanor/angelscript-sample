UCLASS(Abstract)
class UFeatureAnimInstanceRotatingFlower : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData OpenUp;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData OpenIdle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Catch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ClosedIdle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData SpitOut;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMonkeyInFlower;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMonkeyInRange;

	AEvergreenBarrel Barrel;

	UHazePhysicalAnimationComponent PhysicalAnimComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		Barrel = Cast<AEvergreenBarrel>(HazeOwningActor);

		if (Barrel != nullptr && Barrel.SkeletalMesh.DefaultPhysicsProfile != nullptr)
			PhysicalAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Barrel == nullptr)
			return;

		bMonkeyInRange = Barrel.AnimData.bPlayerInRange;

		if (CheckValueChangedAndSetBool(bMonkeyInFlower, Barrel.AnimData.bPlayerInBarrel))
		{
			if (PhysicalAnimComp != nullptr)
			{
				if (bMonkeyInFlower)
					PhysicalAnimComp.Disable(this);
				else
					PhysicalAnimComp.ClearDisable(this, 2);
			}
		}
	}
}
