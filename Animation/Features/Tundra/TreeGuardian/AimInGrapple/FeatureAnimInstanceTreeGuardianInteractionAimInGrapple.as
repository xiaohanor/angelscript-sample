UCLASS(Abstract)
class UFeatureAnimInstanceTreeGuardianInteractionAimInGrapple : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardianInteractionAimInGrapple Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardianInteractionAimInGrappleAnimData AnimData;
		
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator AimValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraPlayerTreeGuardianRangedInteractGrappleAnimData GrappleAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimSpaceVariable;

	UPROPERTY()
	bool bUsingRightAimspace;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
				
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTreeGuardianInteractionAimInGrapple NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardianInteractionAimInGrapple);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		GrappleAnimData = TreeGuardianComp.GrappleAnimData;

	

		//AimValue = FRotator::MakeFromXZ(GrappleAnimData.AttachedAimingDirection, HazeOwningActor.ActorUpVector);
		Print("AimValue: " + AimValue, 0.f);


		AimValues = Player.CalculatePlayerAimAngles();
		bUsingRightAimspace = AimValues.Y >= 0;

	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{

	
			AimValues = Player.CalculatePlayerAimAngles();

		AimSpaceVariable = AimValues;

		if(bUsingRightAimspace)
		{
			bUsingRightAimspace = AimValues.Y >= 0 || AimValues.Y < -90;
			if(bUsingRightAimspace && AimValues.Y < -90)
			{
				float ExtraValue = 90 + AimSpaceVariable.Y;
				AimSpaceVariable.Y = 90 + ExtraValue;
			}
		}
		else
		{
			bUsingRightAimspace = !(AimValues.Y < 0 || AimValues.Y > 90);
			if(!bUsingRightAimspace && AimValues.Y > 90)
			{
				float ExtraValue = 90 - AimSpaceVariable.Y;
				AimSpaceVariable.Y = -90 - ExtraValue;
			}
				}


	}
	

}

