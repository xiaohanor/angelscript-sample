
UCLASS(Abstract)
class UFeatureAnimInstanceDentures : UHazeAnimInstanceBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY()
	ULocomotionFeatureDentures Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDenturesAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAttachedToJaw = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsJumping = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsControlled = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsBitingHand = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBiteInput = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFallingOverJump = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRechargingJumps = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float EnergyAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDamaged = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsRotatingBack = false;

	ADentistBossToolDentures DenturesActor;

	bool bEyeSpringsAreDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		DenturesActor = Cast<ADentistBossToolDentures>(HazeOwningActor);
		DenturesActor.SkelMesh.OnPostResetAllAnimation.AddUFunction(this, n"OnPostAnimationRest");
	}

	UFUNCTION()
	private void OnPostAnimationRest(UHazeSkeletalMeshComponentBase SkelMeshComp)
	{
		bEyeSpringsAreDisabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (Feature != nullptr)
			AnimData = Feature.AnimData;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		if(DenturesActor == nullptr)
			return;
		
		bIsAttachedToJaw = !DenturesActor.bActive;
		bIsJumping = DenturesActor.bIsJumping;
		bIsBitingHand = DenturesActor.bIsBitingLeftHand 
			|| DenturesActor.bIsBitingRightHand;
		bBiteInput = DenturesActor.bBiteInput;
		bIsRechargingJumps = DenturesActor.bIsRechargingJumps;
		bFallingOverJump  = DenturesActor.bFallingOverJump;
		bIsControlled = DenturesActor.ControllingPlayer.IsSet();
		EnergyAlpha = DenturesActor.EnergyAlpha;
		bDamaged = DenturesActor.bDamaged;
		bIsRotatingBack = DenturesActor.bIsRotatingBack;

		ToggleEyeSprings(DenturesActor.EyesSpringinessEnabled.Get());
	}

	private void ToggleEyeSprings(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(!bEyeSpringsAreDisabled)
				return;
			
			auto PhysAnimComp = UHazePhysicalAnimationComponent::Get(HazeOwningActor);
			if (PhysAnimComp != nullptr)
			{
				PhysAnimComp.ClearDisable(this);
				bEyeSpringsAreDisabled = false;
			}
		}
		else
		{
			if(bEyeSpringsAreDisabled)
				return;

			auto PhysAnimComp = UHazePhysicalAnimationComponent::Get(HazeOwningActor);
			if (PhysAnimComp != nullptr)
			{
				PhysAnimComp.Disable(this);
				bEyeSpringsAreDisabled = true;
			}
		}
	}

}