UCLASS(Abstract)
class UFeatureAnimInstanceVortexTrident : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureVortexTrident Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureVortexTridentAnimData AnimData;

	// Add Custom Variables Here


	//Enum is at the bottom of this .as . Where Rader attacks on the arena. Directions are from the player's perspective looking at Rader, so screen left, screen right
	UPROPERTY()
	EMeltdownPhasTwoTridentHitLocation HitLocation;

	//Becomes true when Rader moves to do the summon shark attack. Becomes false when he is tired of it.
	UPROPERTY()
	bool bSummonSharksPhase;

	//Becomes true when Rader moves to raise the trident and go into the slam attack phase. Becomes false when he is tired of it.
	UPROPERTY()
	bool bTridentSlamPhase;

	//Becomes true when Rader slams the trident down
	UPROPERTY()
	bool bSlamAttack;

	//Becomes true when the entire Vortex-phase is finished and we start the transition to the next boss phase
	UPROPERTY()
	bool VortexPhaseFinished;

	AMeltdownBossPhaseTwo Rader;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureVortexTrident NewFeature = GetFeatureAsClass(ULocomotionFeatureVortexTrident);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		Rader = Cast<AMeltdownBossPhaseTwo>(HazeOwningActor);
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (Rader != nullptr)
		{
			bSummonSharksPhase = Rader.bIsSummoningSharks;
			bTridentSlamPhase = Rader.bIsSlammingTrident;
			HitLocation = Rader.TridentHitLocation;
			bSlamAttack = Rader.LastTridentAttackFrame == GFrameNumber-1;
			VortexPhaseFinished = Rader.CurrentAttack != EMeltdownPhaseTwoAttack::Trident;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}


//Where Rader attacks on the arena. Directions are from the player's perspective looking at Rader, so screen left, screen right
enum EMeltdownPhasTwoTridentHitLocation
{
	Left, 
	Mid,
	Right,
	
}