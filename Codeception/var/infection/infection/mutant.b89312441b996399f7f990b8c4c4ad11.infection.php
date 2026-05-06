<?php

namespace Codeception_Basic\Covered;

trait LoggerTrait
{
    private array $logs = [];

    public function log(string $message): void
    {
        $this->logs[] = $message;
    }

    protected function getLogs(): array
    {
        return $this->logs;
    }

    public function clearLogs(): void
    {
        $this->logs = [];
    }

    public function hasLogs(): bool
    {
        return count($this->logs) > 0;
    }
}