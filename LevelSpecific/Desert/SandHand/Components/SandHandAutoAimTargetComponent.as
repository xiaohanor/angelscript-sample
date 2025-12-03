class USandHandAutoAimTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = SandHand::TargetableCategory;
	default MaximumDistance = SandHand::AutoAimRange;
	default AutoAimMaxAngle = 8.0;
}