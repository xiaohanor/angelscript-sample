UFUNCTION(Category = "Player Movement")
mixin bool IsGrappleActive(AHazePlayerCharacter Player)
{
	UPlayerGrappleComponent GrappleComp = UPlayerGrappleComponent::Get(Player);

	if(GrappleComp == nullptr)
		return false;

	return GrappleComp.IsGrappleActive();
}

UFUNCTION(Category = "Player Movement")
mixin void ForcePlayerGrapple(AHazePlayerCharacter Player, AHazeActor GrappleActor)
{
	UGrapplePointBaseComponent GrapplePointComp = UGrapplePointBaseComponent::Get(GrappleActor);
	
	if(GrapplePointComp == nullptr)
		return;

	UPlayerGrappleComponent PlayerGrappleComp = UPlayerGrappleComponent::Get(Player);

	if(PlayerGrappleComp == nullptr)
		return;
	
	PlayerGrappleComp.Data.ForceGrapplePoint = GrapplePointComp;
}

UFUNCTION(Category = "Player Movement")
mixin void ForceWallRun(AGrappleWallrunPoint GrappleWallRunActor, AHazePlayerCharacter Player, ELeftRight Direction, bool bResetHeightLimiter = true)
{
	UGrappleWallrunPointComponent WallRunPoint = UGrappleWallrunPointComponent::Get(GrappleWallRunActor);
	UPlayerWallRunComponent PlayerWallRunComp = UPlayerWallRunComponent::Get(Player);

	if(WallRunPoint == nullptr || PlayerWallRunComp == nullptr)
		return;

	FPlayerWallRunData WallRunData;
	WallRunData = PlayerWallRunComp.TraceForWallRun(Player, WallRunPoint.ForwardVector, FInstigator(GrappleWallRunActor, n"ForceWallRun"));
	
	if(!WallRunData.HasValidData())
		return;

	if(bResetHeightLimiter)
		PlayerWallRunComp.bHasWallRunnedSinceLastGrounded = false;

	UPlayerGrappleComponent GrappleComp = UPlayerGrappleComponent::Get(Player);
	WallRunData.InitialVelocity = Direction == ELeftRight::Left ? WallRunPoint.GetForwardWithEntryAngle() : WallRunPoint.GetBackwardsWithEntryAngle();
	WallRunData.InitialVelocity = WallRunData.InitialVelocity * Math::Max(PlayerWallRunComp.Settings.MinimumSpeed, WallRunPoint.EntrySpeed);
	GrappleComp.AnimData.EnterSide = Direction;

	FRotator TargetRotation = FRotator::MakeFromXZ(WallRunData.InitialVelocity.ConstrainToPlane(Player.MovementWorldUp), Player.MovementWorldUp);
	Player.SetActorRotation(TargetRotation);
	PlayerWallRunComp.StartWallRun(WallRunData);
}