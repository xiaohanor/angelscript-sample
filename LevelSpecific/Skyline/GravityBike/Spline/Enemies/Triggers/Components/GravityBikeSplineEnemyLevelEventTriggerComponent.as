UCLASS(NotBlueprintable)
class UGravityBikeSplineEnemyLevelEventTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	default bImplementsExit = false;
	default bUseEndExtent = false;
	default StartColor = ColorDebug::Green;

	UPROPERTY(EditInstanceOnly)
	FName EventTag;

	private AGravityBikeSplineEnemySpline EnemySpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		EnemySpline = Cast<AGravityBikeSplineEnemySpline>(Owner);
	}

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		EnemySpline.OnEnterLevelEventTrigger.Broadcast(TriggerUserComp, EventTag, this, bIsTeleport);
	}

#if EDITOR
	FString GetDebugString() const override
	{
		FString DebugString = Super::GetDebugString();
		DebugString += f", {EventTag=}";
		return DebugString;
	}
#endif
};