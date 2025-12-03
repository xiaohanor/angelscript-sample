class UAnimInstancePlayerPostProcess : UAnimInstance
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsControlledByCutscene;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector WindVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bOverrideGravity = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector OverrideWorldGravity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HairWeight = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ItemsWeight = 1.0;

	AHazeActor HazeOwningActor;
	UHazeSkeletalMeshComponentBase HazeOwningComponent;

	float WindAlphaInterpSpeed = 2.0;
	float WindAlpha = 0.0;

	AGameSky Sky;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		HazeOwningActor = Cast<AHazeActor>(OwningComponent.GetOwner());
		HazeOwningComponent = Cast<UHazeSkeletalMeshComponentBase>(OwningComponent);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr || !HazeOwningActor.IsA(AHazePlayerCharacter))
			return;

		Sky = AGameSky::Get();
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

		if (HazeOwningComponent == nullptr)
			return;

		if (HazeOwningComponent.bDisableWindInPostProcessABP == true && WindAlpha != 0.0)
			WindAlpha = Math::FInterpConstantTo(WindAlpha, 0.0, DeltaTime, WindAlphaInterpSpeed);
		else if (WindAlpha != 1.0)
			WindAlpha = Math::FInterpConstantTo(WindAlpha, 1.0, DeltaTime, WindAlphaInterpSpeed);

		if (Sky != nullptr)
			WindVelocity = Sky.WindDirection * Sky.WindStrength * 500 * WindAlpha;
		else
			WindVelocity = FVector::ZeroVector;

		if (HazeOwningComponent.IsGravityOverrideActive())
		{
			bOverrideGravity = true;
			OverrideWorldGravity = HazeOwningComponent.GetOverrideGravityDirection() * 980.0;
		}
		else
		{
			bOverrideGravity = false;
		}

		HairWeight = HazeOwningComponent.HairPhysWeight;
		ItemsWeight = HazeOwningComponent.ItemsPhysWeight;
		
		bIsControlledByCutscene = HazeOwningActor.bIsControlledByCutscene;
	}
}