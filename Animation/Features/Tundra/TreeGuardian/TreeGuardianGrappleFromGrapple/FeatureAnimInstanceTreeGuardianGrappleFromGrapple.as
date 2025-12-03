UCLASS(Abstract)
class UFeatureAnimInstanceTreeGuardianGrappleFromGrapple : UHazeFeatureSubAnimInstance



{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardianGrappleFromGrapple Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardianGrappleFromGrappleAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimSpaceVariable;
	
	UPROPERTY()
	bool bUsingRightAimspace;

	


	

	


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraPlayerTreeGuardianRangedInteractGrappleAnimData GrappleAnimData;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;

	






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
		ULocomotionFeatureTreeGuardianGrappleFromGrapple NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardianGrappleFromGrapple);
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


