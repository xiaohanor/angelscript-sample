UCLASS(NotBlueprintable, HideCategories = "Debug Rendering Activation Cooking Tags LOD Collision")
class UGravityBikeSplineEnemyLeadDistanceTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	default bImplementsExit = false;
	default StartColor = ColorDebug::Carrot;
	
    UPROPERTY(EditAnywhere, Category = "Enemy Lead Distance Component")
    float LeadAmount = 1000;

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto EnemyMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(TriggerUserComp.Owner);
		if(EnemyMoveComp == nullptr)
			return;
		
		EnemyMoveComp.LeadAmount = LeadAmount;
	}

#if EDITOR
	FString GetDebugString() const override
	{
		return Super::GetDebugString() + f", LeadAmount: {LeadAmount}";
	}
#endif
};