event void FSkylineTorHammerComponentChangedModeEvent(ESkylineTorHammerMode NewMode, ESkylineTorHammerMode OldMode);

class USkylineTorHammerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	private ESkylineTorHammerMode InternalCurrentMode = ESkylineTorHammerMode::Idle;

	USkylineTorHoldHammerComponent HoldHammerComp;

	FSkylineTorHammerComponentChangedModeEvent OnChangedMode;

	bool bBlockReturn;
	bool bGrabbed;
	bool bInterruptGrabMash;
	bool bDamaged;
	TInstigated<bool> bGroundOffset;

	ESkylineTorHammerMode GetCurrentMode() property
	{
		return InternalCurrentMode;
	}

	private bool bInternalRecall;
	bool GetbRecall() property
	{
		return bInternalRecall;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"Thrown");
		WhipResponse.OnReleased.AddUFunction(this, n"Released");
	}

	UFUNCTION()
	private void Released(UGravityWhipUserComponent UserComponent,
	                      UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		bGrabbed = false;
	}

	UFUNCTION()
	private void Thrown(UGravityWhipUserComponent UserComponent,
	                    UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                    FVector Impulse)
	{
		bGrabbed = false;
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		bGrabbed = true;
	}

	void SetMode(ESkylineTorHammerMode NewMode)
	{
		ESkylineTorHammerMode OldMode = InternalCurrentMode;
		InternalCurrentMode = NewMode;
		bInternalRecall = false;
		OnChangedMode.Broadcast(NewMode, OldMode);
	}

	void InterruptGrabMash()
	{
		bInterruptGrabMash = true;
	}

	void ResetTranslations()
	{
		HoldHammerComp.Hammer.TranslationComp.RelativeLocation = FVector::ZeroVector;
		HoldHammerComp.Hammer.TranslationComp.RelativeRotation = FRotator::ZeroRotator;
		HoldHammerComp.Hammer.ExtraTranslationComp.RelativeLocation = FVector::ZeroVector;
		HoldHammerComp.Hammer.ExtraTranslationComp.RelativeRotation = FRotator::ZeroRotator;
		HoldHammerComp.Hammer.FauxRotateComp.ResetForces();
		HoldHammerComp.Hammer.InvertedFauxRotateComp.ResetForces();
		HoldHammerComp.Hammer.FauxRotateComp.ResetPhysics();
		HoldHammerComp.Hammer.InvertedFauxRotateComp.ResetPhysics();
	}

	void Recall()
	{
		if(!HoldHammerComp.bDetached)
			return;
		bInternalRecall = true;
	}
}

enum ESkylineTorHammerMode
{
	Idle,
	Volley,
	Melee,
	MeleeSecond,
	Whipped,
	Circle,
	Disarmed,
	Return,
	Spiral,
	OpportunityAttack,
	Smash,
	Exposed,
	Stolen,
	MeleeGrounded
}