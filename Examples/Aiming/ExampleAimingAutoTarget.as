
/**
 * Specialized auto aim target for example aiming,
 * allows overriding how exactly the auto aim works.
 */
class UExampleAimingAutoTarget : UAutoAimTargetComponent
{
	default TargetableCategory = n"ExampleAiming";

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Use default auto-aim targeting
		return Super::CheckTargetable(Query);
	}
};