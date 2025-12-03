class USkylineBallBossDetonatorSocketComponent : USceneComponent
{
	ASkylineBallBossAttachedDetonator AttachedDetonator = nullptr;
	ASkylineBallBossThrowableDetonator IncomingDetonator = nullptr;
	bool bSpawningAttached = false;

	UGravityWhipSlingAutoAimComponent AutoAimChildComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (NumChildrenComponents > 0)
		{
			USceneComponent ChildComp = GetChildComponent(0);
			if (ChildComp != nullptr)
				AutoAimChildComp = Cast<UGravityWhipSlingAutoAimComponent>(ChildComp);
		}
	}

	bool CanTarget()
	{
		return !bSpawningAttached && IncomingDetonator == nullptr && AttachedDetonator == nullptr;
	}
}