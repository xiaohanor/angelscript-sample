class ASanctuaryBloodGateDarkPortalHandle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp03;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp04;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp05;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp06;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp07;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp08;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp09;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp10;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp11;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalTargetComponent TargetComp12;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};