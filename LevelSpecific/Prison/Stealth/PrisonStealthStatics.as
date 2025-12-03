namespace PrisonStealth
{
    AHazePlayerCharacter GetStealthManagerPlayer()
    {
        return Game::Zoe;
    }

	UFUNCTION(BlueprintPure)
    UPrisonStealthManager GetStealthManager()
    {
        return UPrisonStealthManager::GetOrCreate(GetStealthManagerPlayer());
    }
};