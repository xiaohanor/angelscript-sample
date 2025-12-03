class UPlayerSplineLockResolverExtension : USplineLockResolverExtension
{
#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		auto PlayerSplineLockComp = UPlayerSplineLockComponent::Get(Resolver.Owner);
		if(PlayerSplineLockComp != nullptr)
		{
			FinalSectionLog.Section("Component")
				.Value("Zone", PlayerSplineLockComp.GetCurrentSplineZone())
			;
		}
	}
#endif
};