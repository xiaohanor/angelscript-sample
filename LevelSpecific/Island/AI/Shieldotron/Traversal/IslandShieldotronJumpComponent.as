enum EIslandShieldotronJumpState
{
	Grounded,
	Launching,
	Midair,
	Landing,
	MAX
}
class UIslandShieldotronJumpComponent : UActorComponent
{
	bool bSkipLandingAnimation = false; // for when entrance animation also contains a landing.
	bool bIsJumping = false; // TODO: replace with state enum
	bool bIsLanding = false; // TODO: replace with state enum
}