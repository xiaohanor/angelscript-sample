event void FTundraShellyShellEnterSignature();
event void FTundraShellyShellExitSignature();

class UTundraShellyShellComponent : UActorComponent
{
	bool bShelled;

	FTundraShellyShellEnterSignature OnEnter;
	FTundraShellyShellExitSignature OnExit;

	void EnterShell()
	{
		bShelled = true;
		OnEnter.Broadcast();
	}

	void ExitShell()
	{
		bShelled = false;
		OnExit.Broadcast();
	}
}