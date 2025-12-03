class USkylineTorHammerStolenComponent : UActorComponent
{
	private UGravityWhipUserComponent InternalWhipUserComp;
	UGravityWhipTargetComponent WhipTarget;
	USkylineTorHammerStolenPlayerComponent PlayerStolenComp;
	bool bAttack;
	bool bIdle;
	bool bStolen;
	float FinalBlowCameraDuration;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PlayerFinalBlowAnim;

	UGravityWhipUserComponent GetWhipUserComp() property
	{
		return InternalWhipUserComp;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipTarget = UGravityWhipTargetComponent::GetOrCreate(Owner);
	}

	void Steal(UGravityWhipUserComponent _WhipUserComp)
	{
		InternalWhipUserComp = _WhipUserComp;
		bAttack = false;
		bStolen = true;
		bIdle = true;
		PlayerStolenComp = USkylineTorHammerStolenPlayerComponent::GetOrCreate(_WhipUserComp.Owner);
		PlayerStolenComp.bStolen = true;
	}

	void Release()
	{
		InternalWhipUserComp = nullptr;
		bAttack = false;
		bStolen = false;
		PlayerStolenComp.bStolen = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bStolen)
		{
			bAttack = PlayerStolenComp.bAttack;
		}
	}
}