
enum EIslandNunchuckMoveAssetPriority
{
	Default,
	High
}

UCLASS(Abstract)
class UIslandNunchuckMoveAssetBase : UDataAsset
{
	UPROPERTY(Category = "Settings")
	bool bIsPartOfComboChain = false;

	/** The name of the combo chain, if this is a combo chain
	 * If it is a chain, the next index in the chain name will always have prio to activate
	 */
	UPROPERTY(Category = "Settings", meta = (EditCondition="bIsPartOfComboChain", EditConditionHides))
	FName ComboChainName = NAME_None;

	// The number this should have in the combo chain 1 is minimum
	UPROPERTY(Category = "Settings", meta = (ClampMin = "1", EditCondition="bIsPartOfComboChain", EditConditionHides))
	int ComboChainIndex = 1;

	/** If true, this move will always reset 
	 * the combo chain when finished.
	 * This makes the combos start from the beginning again.
	*/ 
	UPROPERTY(Category = "Settings", meta = (EditCondition="bIsPartOfComboChain", EditConditionHides))
	bool bEndComboChain = true;

	// Tags are used to enable certain moves by targetable components
	UPROPERTY(Category = "Settings")
	TArray<FName> Tags;

	// All the impacts that this move can trigger
	UPROPERTY(Category = "Settings")
	TArray<FIslandNunchuckMoveImpactData> TriggerImpacts;

	UPROPERTY(Category = "Settings")
	EIslandNunchuckMoveAssetPriority Priority = EIslandNunchuckMoveAssetPriority::Default;

	bool IsValidComboChain() const
	{
		if(!bIsPartOfComboChain)
			return false;

		if(ComboChainName == NAME_None)
			return false;

		if(ComboChainIndex <= 0)
			return false;

		return true;
	}

	bool IsFirstInComboChain() const
	{
		if(!IsValidComboChain())
			return false;

		return ComboChainIndex == 1;
	}

	bool IsLastInComboChain() const
	{
		if(!IsValidComboChain())
			return false;

		return bEndComboChain;
	}
}

class UIslandNunchuckMoveAsset : UDataAsset
{
	UPROPERTY(Category = "Moves")
	TArray<UIslandNunchuckMoveAsset> MoveSheets;

	UPROPERTY(Category = "Moves")
	TArray<UIslandNunchuckMoveAssetBase> Moves;
}

// A struct containing all the impact information and when to trigger the impacts
// so we can use it on multiple moves
struct FIslandNunchuckPendingImpactData
{
	TArray<FIslandNunchuckMoveImpactData> ImpactInfos;
	TArray<float> TriggerTimeAlphas;
	float TotalMoveLength = -1;

	void Setup(UIslandNunchuckMoveAssetBase MoveAsset, FIslandNunchuckAnimationData Animation)
	{
		if(Animation.PlayerAnimation.Sequence == nullptr)
		{
			#if EDITOR
			devCheck(ImpactInfos.Num() == 0, f"The move asset {MoveAsset} has {ImpactInfos.Num()} impact infos but no player animation.");
			#endif

			return;
		}

		ImpactInfos = MoveAsset.TriggerImpacts;
		TotalMoveLength = Animation.GetMovePlayLength();
		TriggerTimeAlphas.Reset();

		TArray<float32> TriggerImpactTimes;
		Animation.PlayerAnimation.Sequence.GetAnimNotifyTriggerTimes(
			UIslandNunchuckTriggerImpactMarkerNotify,
			TriggerImpactTimes);
		
		#if EDITOR
		devCheck(ImpactInfos.Num() == TriggerImpactTimes.Num(), f"The move asset {MoveAsset} has {ImpactInfos.Num()} impact infos but {TriggerImpactTimes.Num()} TriggerImpactMarkerNotifys");
		#endif

		for(int i = 0; i < TriggerImpactTimes.Num(); ++i)
		{
			float Alpha = TriggerImpactTimes[i] / Animation.PlayerAnimation.Sequence.GetPlayLength();
			TriggerTimeAlphas.Add(Alpha);
		}
	}

	void Update(float ActivePlayLength, UPlayerIslandNunchuckUserComponent MeleeComp)	
	{
		const float TimeAlpha = Math::Min(ActivePlayLength / TotalMoveLength, 1);
		while(TriggerTimeAlphas.Num() > 0 && TimeAlpha >= TriggerTimeAlphas[0])
		{
			MeleeComp.AddAvailableImpact(ImpactInfos[0]);
			TriggerTimeAlphas.RemoveAt(0);
		}
	}
}

enum EIslandNunchuckGroundedSettingsType
{
	Grounded,
	InAir
}

enum EIslandNunchuckTriggerSettingsType
{
	True,
	False,
}

struct FIslandNunchuckRootMotion
{
	bool bHasRootmotion = false;
	UAnimSequence Sequense;
	FHazeLocomotionTransform LocomotionTransform;
	FVector ExpectedMoveAmount = FVector::ZeroVector;
	FVector AccumulateMoveAmount = FVector::ZeroVector;
	float TotalPlayLength = 0;

	void Init(FIslandNunchuckAnimationData Animation)
	{
		bHasRootmotion = false;
		
		if(!Animation.IsValidForPlayer())
			return;

		if(!Animation.PlayerAnimation.Sequence.ExtractTotalRootMotion(LocomotionTransform))
			return;
		
		if(LocomotionTransform.DeltaTranslation.IsNearlyZero())
			return;
		
		bHasRootmotion = true;
		Sequense = Animation.PlayerAnimation.Sequence;
		ExpectedMoveAmount.X = FVector::ForwardVector.DotProduct(LocomotionTransform.DeltaTranslation);
		ExpectedMoveAmount.Y = FVector::RightVector.DotProduct(LocomotionTransform.DeltaTranslation);
		ExpectedMoveAmount.Z = FVector::UpVector.DotProduct(LocomotionTransform.DeltaTranslation);
		TotalPlayLength = Animation.GetMovePlayLength();
		AccumulateMoveAmount = FVector::ZeroVector;
	}

	void Init(FIslandNunchuckAnimationData Animation, FVector ExpectedDeltaTranslation)
	{
		bHasRootmotion = false;
		
		if(!Animation.IsValidForPlayer())
			return;

		if(!Animation.PlayerAnimation.Sequence.ExtractTotalRootMotion(LocomotionTransform))
			return;
		
		if(LocomotionTransform.DeltaTranslation.IsNearlyZero())
			return;
		
		bHasRootmotion = true;
		Sequense = Animation.PlayerAnimation.Sequence;
		ExpectedMoveAmount = ExpectedDeltaTranslation;
		TotalPlayLength = Animation.GetMovePlayLength();
		AccumulateMoveAmount = FVector::ZeroVector;
	}

	FVector GetLocalRootMotionAmount(float CurrentAnimationTime)
	{
		if(!bHasRootmotion)
			return FVector::ZeroVector;

		return Sequense.GetDeltaMoveForMoveRatio(
				AccumulateMoveAmount, 
				CurrentAnimationTime, 
				ExpectedMoveAmount, 
				TotalPlayLength);
	}

	void Clear()
	{
		bHasRootmotion = false;
	}
}