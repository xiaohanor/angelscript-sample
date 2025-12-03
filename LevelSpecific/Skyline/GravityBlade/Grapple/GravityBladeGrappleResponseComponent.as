event void FGravityBladeThrowSignature(UGravityBladeGrappleUserComponent GrappleComp, FGravityBladeThrowData ThrowData);
event void FGravityBladePullSignature(UGravityBladeGrappleUserComponent GrappleComp);

class UGravityBladeGrappleResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Called when the player starts grappling the object.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityBladeThrowSignature OnThrowStart;
	// Called when the blade has reached the object.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityBladeThrowSignature OnThrowEnd;
	// Called when the player starts moving to the object.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityBladePullSignature OnPullStart;
	// Called when the player has reached the object.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FGravityBladePullSignature OnPullEnd;

	void ThrowStart(UGravityBladeGrappleUserComponent GrappleComp, const FGravityBladeThrowData& ThrowData)
	{
		OnThrowStart.Broadcast(GrappleComp, ThrowData);
	}

	void ThrowEnd(UGravityBladeGrappleUserComponent GrappleComp, const FGravityBladeThrowData& ThrowData)
	{
		OnThrowEnd.Broadcast(GrappleComp, ThrowData);
	}

	void PullStart(UGravityBladeGrappleUserComponent GrappleComp)
	{
		OnPullStart.Broadcast(GrappleComp);
	}

	void PullEnd(UGravityBladeGrappleUserComponent GrappleComp)
	{
		OnPullEnd.Broadcast(GrappleComp);
	}
}