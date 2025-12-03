UCLASS(NotBlueprintable, HideCategories = "Debug ComponentTick Activation Cooking Disable Tags Navigation")
class USkylineBossCoreComponent : UActorComponent
{
	access ExposeCore = private, USkylineBossExposeCoreCapability, USkylineBossStopExposeCoreCapability;

	private ASkylineBoss Boss;
	private bool bCoreExposed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);
			
		Boss.CoreCollision.AddComponentCollisionBlocker(this);
		Boss.CoreAutoAimTargetComponent.Disable(this);
		Boss.CoreVisual.SetVisibility(false, true);
	}

	access:ExposeCore
	void StartExposeCore()
	{
		if(!ensure(!IsCoreExposed()))
			return;

		bCoreExposed = true;
		Boss.CoreCollision.RemoveComponentCollisionBlocker(this);
		Boss.CoreAutoAimTargetComponent.Enable(this);
		Boss.CoreVisual.SetVisibility(true, true);
	}

	access:ExposeCore
	void StopExposeCore()
	{
		if(!ensure(IsCoreExposed()))
			return;

		bCoreExposed = false;
		Boss.CoreCollision.AddComponentCollisionBlocker(this);
		Boss.CoreAutoAimTargetComponent.Disable(this);
		Boss.CoreVisual.SetVisibility(false, true);
	}

	bool IsCoreExposed() const
	{
		return bCoreExposed;
	}
};