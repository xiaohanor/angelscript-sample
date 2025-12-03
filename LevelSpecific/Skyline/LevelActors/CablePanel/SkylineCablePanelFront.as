class ASkylineCablePanelFront : AWhipSlingableObject
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Collision.AddComponentCollisionBlocker(this);
	}

	void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents) override
	{
		Super::OnGrabbed(UserComponent, TargetComponent, OtherComponents);
		
		Collision.RemoveComponentCollisionBlocker(this);
	}
};